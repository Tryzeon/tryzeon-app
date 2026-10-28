import { publicImageUrl } from "../lib/publicImage";

export interface CatalogItem {
  productId: string;
  name: string;
  price: number;
  storeName: string | null;
  imageUrls: string[];
  garmentType: string | null;
  purchaseLink: string | null;
  description: string | null;
}

export interface CatalogStore {
  id: string;
  name: string;
}

/** Both shop RPCs return a product's colours in cover order. */
function coverImageKeys(colors: unknown): string[] {
  const cover: unknown = Array.isArray(colors) ? colors[0] : undefined;
  if (typeof cover !== "object" || cover === null) return [];
  const paths = (cover as Record<string, unknown>).image_paths;
  return Array.isArray(paths)
    ? paths.filter((k): k is string => typeof k === "string" && k.length > 0)
    : [];
}

/**
 * A product whose cover colour has no usable image still becomes an item, just with an empty
 * imageUrls. Dropping it here would put items.length out of step with the row
 * count the pagination arithmetic relies on, and would make the product vanish
 * from the store's own catalog instead of showing that it lacks photos.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem {
  const r = (row ?? {}) as Record<string, unknown>;
  const keys = coverImageKeys(r.product_colors);

  const store = (r.store_profiles ?? null) as Record<string, unknown> | null;
  const link = r.purchase_link;
  const garmentType = r.garment_type;
  const description = r.description;

  return {
    productId: String(r.id),
    name: typeof r.name === "string" ? r.name : "",
    price: Number(r.price),
    storeName: store && typeof store.name === "string" ? store.name : null,
    imageUrls: keys.map((k) => publicImageUrl(baseUrl, k)),
    garmentType: typeof garmentType === "string" ? garmentType : null,
    purchaseLink: typeof link === "string" && link.length > 0 ? link : null,
    description:
      typeof description === "string" && description.trim().length > 0
        ? description
        : null,
  };
}
