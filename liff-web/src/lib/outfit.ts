import type { ResolvedItem } from "../state/chat";

export interface OutfitPurchase {
  count: number;
  total: number;
}

/** Null when every piece is already in the wardrobe. */
export function outfitPurchase(pieces: ResolvedItem[]): OutfitPurchase | null {
  const prices = pieces.flatMap((piece) => piece.kind === "product" ? [piece.item.price] : []);
  if (prices.length === 0) return null;
  return { count: prices.length, total: prices.reduce((sum, price) => sum + price, 0) };
}

/** "共" when every piece is for sale; "再買" when the wardrobe already covers part of the look. */
export function purchaseCountText(purchase: OutfitPurchase, pieceCount: number): string {
  return purchase.count < pieceCount ? `再買 ${purchase.count} 件` : `共 ${purchase.count} 件`;
}

const garmentTypeOf = (piece: ResolvedItem): string | null =>
  piece.kind === "product" ? piece.item.garmentType : piece.garmentType;

/** Outerwear leads: it is the layer the look is seen in, and the lead cell is the largest. */
export function collageOrder(pieces: ResolvedItem[]): ResolvedItem[] {
  const lead = pieces.findIndex((piece) => garmentTypeOf(piece) === "outerwear");
  return lead <= 0 ? pieces : [pieces[lead], ...pieces.filter((_, i) => i !== lead)];
}
