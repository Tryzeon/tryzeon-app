import { fetchRowsByIds, hasProductImage } from "../_shared/chat/hydrate.ts";
import type { Enums } from "../_shared/database.types.ts";
import { publicImageUrl } from "../_shared/public-images.ts";
import { CARD_COLOR, pickBubble, sourceLine } from "./card-kit.ts";
import { productTryonPostbackData } from "./postback.ts";
import { asJsonObject, type DbClient } from "../_shared/supabase.ts";

export const PRODUCT_CARD_SELECT =
  "id, name, price, image_paths, garment_type, purchase_link, store_profiles!products_store_id_fkey(name)";

export interface ProductInfo {
  id: string;
  name: string;
  price: number;
  storeName: string | null;
  purchaseUrl: string | null;
}

export interface LineProduct extends ProductInfo {
  imageUrl: string;
  garmentType: Enums<"garment_type">;
}

/**
 * The image check stays here even though this no longer builds a URL from it: an
 * image-less product is not merely an invisible card, it is un-try-on-able —
 * `resolveProductGarment` rejects it for having no garment material — so the one
 * check answers both questions.
 */
export function toProductInfo(
  // deno-lint-ignore no-explicit-any
  row: Record<string, any>,
): ProductInfo | null {
  if (!hasProductImage(row)) return null;

  const store = row.store_profiles as { name?: string } | null;
  return {
    id: String(row.id),
    name: String(row.name),
    price: Number(row.price),
    storeName: store?.name ?? null,
    purchaseUrl: row.purchase_link ?? null,
  };
}

export function toLineProduct(
  // deno-lint-ignore no-explicit-any
  row: Record<string, any>,
  imagesBaseUrl: string,
): LineProduct | null {
  const info = toProductInfo(row);
  if (!info) return null;

  const key = (row.image_paths as string[])[0];
  return {
    ...info,
    imageUrl: publicImageUrl(imagesBaseUrl, key),
    garmentType: row.garment_type,
  };
}

export function fetchProductRows(
  admin: DbClient,
  ids: string[],
  imagesBaseUrl: string,
): Promise<Map<string, LineProduct>> {
  return fetchRowsByIds(
    admin.from("products").select(PRODUCT_CARD_SELECT).eq("status", "active"),
    ids,
    (row) => toLineProduct(row, imagesBaseUrl),
  );
}

/**
 * Null when the id names nothing that can be acted on — unlisted, gone, or no
 * image; a failed lookup throws instead, since a missing product is something
 * the user can be told about and a broken query is ours to fix.
 *
 * Unlisted counts because `handleProductTryon` runs this before charging quota:
 * whatever the core would later reject has to be rejected here too, or the tap
 * costs the user a try-on and returns a generic error — and a card can sit in a
 * LINE thread long after the store took the product down. This path runs on the
 * service-role client, where an RLS policy would not apply.
 */
export async function fetchProductInfo(
  admin: DbClient,
  productId: string,
): Promise<ProductInfo | null> {
  const { data, error } = await admin.rpc("get_shop_product", {
    p_id: productId,
  });

  if (error) throw new Error(`product lookup failed: ${error.message}`);
  const row = asJsonObject<Record<string, unknown>>(data);
  return row ? toProductInfo(row) : null;
}

/**
 * A LINE uri action only accepts an absolute http(s) link, and one it rejects
 * fails the whole send rather than the one button — so a link that cannot be an
 * action simply isn't offered as one.
 *
 * Checked with the `URL` parser, not a prefix test: `startsWith("http")` also
 * accepts `"httpfoo://x"`, and because `URL` normalizes a single-slash scheme
 * into a double-slash one, checking only the parsed protocol would wave through
 * `"https:/one-slash"`.
 */
export function purchaseAction(product: ProductInfo): object | null {
  const url = product.purchaseUrl;
  if (!url) return null;

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }

  const isHttpOrHttps = parsed.protocol === "http:" ||
    parsed.protocol === "https:";
  const hasDoubleSlash = url.toLowerCase().startsWith(`${parsed.protocol}//`);
  return isHttpOrHttps && hasDoubleSlash
    ? { type: "uri", label: "前往購買", uri: url }
    : null;
}

export function priceText(price: number): string {
  return `NT$${Math.round(price).toLocaleString("en-US")}`;
}

/**
 * Who made it, what it is, what it costs: the source line leads in ink, the name
 * steps back to muted regular so only the source and the price carry weight.
 */
export function productInfoContents(product: ProductInfo): object[] {
  return [
    ...(product.storeName ? [sourceLine(product.storeName.toUpperCase())] : []),
    {
      type: "text",
      ...(product.storeName ? { margin: "4px" } : {}),
      text: product.name,
      size: "sm",
      color: CARD_COLOR.mutedText,
      wrap: true,
      maxLines: 2,
    },
    {
      type: "text",
      margin: "6px",
      text: priceText(product.price),
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.primary,
    },
  ];
}

const LIFF_PRODUCT_PATH = "/product";

export function productDetailUrl(liffUrl: string, productId: string): string {
  return `${liffUrl}${LIFF_PRODUCT_PATH}/${productId}`;
}

export function productItemBubble(
  product: LineProduct,
  highlight: string | undefined,
  liffUrl: string,
): object {
  return pickBubble({
    imageUrl: product.imageUrl,
    highlight,
    source: product.storeName?.toUpperCase(),
    name: product.name,
    value: { text: priceText(product.price), muted: false },
    tryonAction: {
      type: "postback",
      label: "試穿",
      data: productTryonPostbackData(product.id),
      // Clamped: `displayText` fails the whole send past 300 characters, and a
      // product name has no length constraint.
      displayText: `試穿「${clampProductName(product.name)}」`,
    },
    detailAction: {
      type: "uri",
      label: "商品詳情",
      uri: productDetailUrl(liffUrl, product.id),
    },
  });
}

/**
 * A product name capped for a field LINE limits as one all-or-nothing check on
 * the whole message — postback `displayText` at 300 characters, flex `altText`
 * at 400 — where going over fails the entire send, not just this piece of text.
 * `products.name` is bare `text` in Postgres with no length constraint, so
 * nothing upstream stops a name from reaching either cap.
 *
 * The cap is far below both: a name past ~40 characters is already unreadable on
 * a card.
 */
const MAX_CLAMPED_NAME_CHARS = 40;

export function clampProductName(name: string): string {
  return name.length > MAX_CLAMPED_NAME_CHARS
    ? `${name.slice(0, MAX_CLAMPED_NAME_CHARS)}…`
    : name;
}
