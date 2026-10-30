export interface ProductColorRow {
  id: string;
  name: string | null;
  image_paths: string[];
}

interface OrderableByReferencedTable {
  order(column: string, options: { referencedTable: string }): this;
}

const COLORS = "product_colors";

/** PostgREST returns an embedded relation unordered unless asked; the cover is the first colour in this order, as in the shop RPCs. */
export const orderProductColors = <Q extends OrderableByReferencedTable>(
  query: Q,
): Q =>
  query
    .order("position", { referencedTable: COLORS })
    .order("created_at", { referencedTable: COLORS })
    .order("id", { referencedTable: COLORS });

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null;

function toColorRow(value: unknown): ProductColorRow | undefined {
  if (!isRecord(value) || typeof value.id !== "string") return undefined;
  if (!Array.isArray(value.image_paths)) return undefined;
  const imagePaths = value.image_paths.filter((p): p is string =>
    typeof p === "string" && p.length > 0
  );
  if (imagePaths.length === 0) return undefined;
  return {
    id: value.id,
    name: typeof value.name === "string" ? value.name : null,
    image_paths: imagePaths,
  };
}

/** Every colour with a usable image, in the order delivered, so the first is the cover. */
export function productColors(
  row: { product_colors?: unknown },
): ProductColorRow[] {
  if (!Array.isArray(row.product_colors)) return [];
  return row.product_colors.flatMap((entry) => toColorRow(entry) ?? []);
}

/** No id means the cover; an id the product does not carry is never swapped for another colour. */
export function pickColor<Color>(
  colors: readonly Color[],
  colorId: string | undefined,
): Color | undefined {
  return colorId === undefined
    ? colors[0]
    : colors.find((c) => isRecord(c) && c.id === colorId);
}

export function productColor(
  row: { product_colors?: unknown },
  colorId: string | undefined,
): ProductColorRow | undefined {
  if (!Array.isArray(row.product_colors)) return undefined;
  return toColorRow(pickColor(row.product_colors, colorId));
}

export const coverImagePath = (
  row: { product_colors?: unknown },
): string | undefined => productColor(row, undefined)?.image_paths[0];
