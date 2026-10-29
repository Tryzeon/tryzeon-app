/**
 * The action names were renamed to `tryon_product` / `tryon_wardrobe`, so a
 * card already sent under the old `tryon` name is one more shape parsing
 * rejects — back-compat for it was declined on purpose, not missed.
 */
import { ANSWER_LIMITS, type ItemRef } from "../_shared/chat/index.ts";
import { isUuid } from "../_shared/text.ts";

const TRYON_PRODUCT = "tryon_product";
const TRYON_WARDROBE = "tryon_wardrobe";
const TRYON_OUTFIT = "tryon_outfit";

export function productTryonPostbackData(
  productId: string,
  colorId: string,
): string {
  return new URLSearchParams({
    a: TRYON_PRODUCT,
    pid: productId,
    cid: colorId,
  }).toString();
}

export function wardrobeTryonPostbackData(wardrobeItemId: string): string {
  return new URLSearchParams({ a: TRYON_WARDROBE, wid: wardrobeItemId })
    .toString();
}

const GARMENT_KIND = { product: "p", wardrobe: "w" } as const;

export function outfitTryonPostbackData(pieces: ItemRef[]): string {
  return new URLSearchParams({
    a: TRYON_OUTFIT,
    g: pieces.map(({ type, id }) => `${GARMENT_KIND[type]}:${id}`).join(","),
  }).toString();
}

function parseGarment(token: string): ItemRef | null {
  const [kind, id, ...rest] = token.split(":");
  if (rest.length > 0 || !id || !isUuid(id)) return null;
  if (kind === GARMENT_KIND.product) return { type: "product", id };
  if (kind === GARMENT_KIND.wardrobe) return { type: "wardrobe", id };
  return null;
}

function isGarment(item: ItemRef | null): item is ItemRef {
  return item !== null;
}

export type Postback =
  | { kind: "product"; productId: string; colorId: string }
  | { kind: "wardrobe"; wardrobeItemId: string }
  | { kind: "outfit"; pieces: ItemRef[] };

export function parsePostback(data: unknown): Postback | null {
  if (typeof data !== "string") return null;

  const params = new URLSearchParams(data);
  const action = params.get("a");

  if (action === TRYON_PRODUCT) {
    const productId = params.get("pid");
    const colorId = params.get("cid");
    return productId && isUuid(productId) && colorId && isUuid(colorId)
      ? { kind: "product", productId, colorId }
      : null;
  }
  if (action === TRYON_WARDROBE) {
    const wardrobeItemId = params.get("wid");
    return wardrobeItemId && isUuid(wardrobeItemId)
      ? { kind: "wardrobe", wardrobeItemId }
      : null;
  }
  if (action === TRYON_OUTFIT) {
    const tokens = (params.get("g") ?? "").split(",");
    const counted = tokens.length >= ANSWER_LIMITS.MIN_OUTFIT_PIECES &&
      tokens.length <= ANSWER_LIMITS.MAX_OUTFIT_PIECES;
    if (!counted) return null;
    const pieces = tokens.map(parseGarment);
    if (!pieces.every(isGarment)) return null;
    return { kind: "outfit", pieces };
  }
  return null;
}
