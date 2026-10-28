export interface ProductColorRow {
  id: string;
  name: string | null;
  image_paths: string[];
  position: number;
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

export function coverColor(
  row: { product_colors?: unknown },
): ProductColorRow | undefined {
  if (!Array.isArray(row.product_colors)) return undefined;
  const first: unknown = row.product_colors[0];
  if (!isRecord(first) || typeof first.id !== "string") return undefined;
  if (!Array.isArray(first.image_paths)) return undefined;
  const imagePaths = first.image_paths.filter((p): p is string =>
    typeof p === "string" && p.length > 0
  );
  if (imagePaths.length === 0) return undefined;
  return {
    id: first.id,
    name: typeof first.name === "string" ? first.name : null,
    image_paths: imagePaths,
    position: typeof first.position === "number" ? first.position : 0,
  };
}

export const coverImagePath = (
  row: { product_colors?: unknown },
): string | undefined => coverColor(row)?.image_paths[0];
