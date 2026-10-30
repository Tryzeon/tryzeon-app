/**
 * The action names were renamed to `tryon_product` / `tryon_wardrobe`, so a
 * card already sent under the old `tryon` name is one more shape parsing
 * rejects — back-compat for it was declined on purpose, not missed.
 */
import { ANSWER_LIMITS, type WardrobeItemRef } from "../_shared/chat/index.ts";
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

export type OutfitPieceRef =
  | { type: "product"; id: string; colorId: string }
  | WardrobeItemRef;

function garmentToken(piece: OutfitPieceRef): string {
  if (piece.type === "wardrobe") {
    return `${GARMENT_KIND.wardrobe}:${piece.id}`;
  }
  return `${GARMENT_KIND.product}:${piece.id}:${piece.colorId}`;
}

export function outfitTryonPostbackData(pieces: OutfitPieceRef[]): string {
  return new URLSearchParams({
    a: TRYON_OUTFIT,
    g: pieces.map(garmentToken).join(","),
  }).toString();
}

function parseGarment(token: string): OutfitPieceRef | null {
  const [kind, id, colorId, ...rest] = token.split(":");
  if (!id || !isUuid(id)) return null;
  if (kind === GARMENT_KIND.product) {
    return rest.length === 0 && colorId && isUuid(colorId)
      ? { type: "product", id, colorId }
      : null;
  }
  if (kind === GARMENT_KIND.wardrobe) {
    return colorId === undefined ? { type: "wardrobe", id } : null;
  }
  return null;
}

function isGarment(item: OutfitPieceRef | null): item is OutfitPieceRef {
  return item !== null;
}

export type Postback =
  | { kind: "product"; productId: string; colorId: string }
  | { kind: "wardrobe"; wardrobeItemId: string }
  | { kind: "outfit"; pieces: OutfitPieceRef[] };

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
