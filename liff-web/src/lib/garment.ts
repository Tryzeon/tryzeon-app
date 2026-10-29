import { coverColor, hasColorChoice, type CatalogColor, type CatalogItem } from "../api/catalog-row";
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
  return piece.kind === "product" ? productGarment(piece.item) : { wardrobeItemId: piece.id };
}

export function productGarment(
  item: CatalogItem,
  color: CatalogColor | null = coverColor(item),
): Garment {
  return color ? { productId: item.productId, colorId: color.id } : { productId: item.productId };
}

export function productCaption(item: CatalogItem, color: CatalogColor): string {
  return hasColorChoice(item) && color.name ? `${item.name} · ${color.name}` : item.name;
}

const CARD_TAG_COUNT = 2;

export function wardrobeCardName(garmentType: string | null, tags: string[]): string {
  return [garmentTypeLabel(garmentType), ...tags.slice(0, CARD_TAG_COUNT)].join(" · ");
}
