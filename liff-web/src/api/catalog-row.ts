import { publicImageUrl } from "../lib/publicImage";

export interface CatalogColor {
  id: string;
  name: string | null;
  imageUrls: string[];
}

export interface CatalogItem {
  productId: string;
  name: string;
  price: number;
  storeName: string | null;
  colors: CatalogColor[];
  garmentType: string | null;
  purchaseLink: string | null;
  description: string | null;
}

export interface CatalogStore {
  id: string;
  name: string;
}

function buildColors(raw: unknown, baseUrl: string): CatalogColor[] {
  if (!Array.isArray(raw)) return [];
  const colors: CatalogColor[] = [];
  for (const entry of raw) {
    if (typeof entry !== "object" || entry === null) continue;
    const c = entry as Record<string, unknown>;
    const paths = Array.isArray(c.image_paths) ? c.image_paths : [];
    const imageUrls = paths
      .filter((k): k is string => typeof k === "string" && k.length > 0)
      .map((k) => publicImageUrl(baseUrl, k));
    if (typeof c.id !== "string" || imageUrls.length === 0) continue;
    colors.push({
      id: c.id,
      name: typeof c.name === "string" && c.name.length > 0 ? c.name : null,
      imageUrls,
    });
  }
  return colors;
}

export function coverColor(item: CatalogItem): CatalogColor | null {
  return item.colors[0] ?? null;
}

export function coverImageUrl(item: CatalogItem): string | null {
  return coverColor(item)?.imageUrls[0] ?? null;
}

export function hasColorChoice(item: CatalogItem): boolean {
  return item.colors.length > 1;
}

export function resolveColor(
  item: CatalogItem,
  colorId: string | null | undefined,
): CatalogColor | null {
  return item.colors.find((c) => c.id === colorId) ?? coverColor(item);
}

/**
 * A product with no colour that has a usable image still becomes an item, just
 * with no colours. Dropping it here would put items.length out of step with the
 * row count the pagination arithmetic relies on, and would make the product
 * vanish from the store's own catalog instead of showing that it lacks photos.
 * The RPCs return colours in cover order.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem {
  const r = (row ?? {}) as Record<string, unknown>;

  const store = (r.store_profiles ?? null) as Record<string, unknown> | null;
  const link = r.purchase_link;
  const garmentType = r.garment_type;
  const description = r.description;

  return {
    productId: String(r.id),
    name: typeof r.name === "string" ? r.name : "",
    price: Number(r.price),
    storeName: store && typeof store.name === "string" ? store.name : null,
    colors: buildColors(r.product_colors, baseUrl),
    garmentType: typeof garmentType === "string" ? garmentType : null,
    purchaseLink: typeof link === "string" && link.length > 0 ? link : null,
    description:
      typeof description === "string" && description.trim().length > 0
        ? description
        : null,
  };
}
