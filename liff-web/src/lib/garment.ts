import type { Garment } from "../api/tryon";
import type { ResolvedItem } from "../state/chat";

const GARMENT_TYPE_LABEL: Record<string, string> = {
  top: "上衣",
  pants: "褲子",
  skirt: "裙子",
  one_piece: "連身",
  outerwear: "外套",
  others: "其他",
};

export function garmentTypeLabel(code: string | null): string {
  return (code !== null && GARMENT_TYPE_LABEL[code]) || "單品";
}

export function tryonGarment(piece: ResolvedItem): Garment {
  return piece.kind === "product" ? { productId: piece.item.productId } : { wardrobeItemId: piece.id };
}

const CARD_TAG_COUNT = 2;

export function wardrobeCardName(garmentType: string | null, tags: string[]): string {
  return [garmentTypeLabel(garmentType), ...tags.slice(0, CARD_TAG_COUNT)].join(" · ");
}
