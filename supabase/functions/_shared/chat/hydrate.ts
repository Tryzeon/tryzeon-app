import { isUuid } from "../text.ts";
import { outfitsOf, picksOf, PRODUCT_SELECT, WARDROBE_SELECT } from "./logic.ts";
import type { AnswerHydrator, ContentBlock, ItemRef } from "./types.ts";
import type { DbClient } from "../supabase.ts";

/**
 * The one thing this needs of a PostgREST query builder: `.in("id", …)`, then
 * awaited. Structural rather than the real builder type so callers keep the row
 * shape their `.select()` inferred without this signature naming the five
 * schema type parameters that would otherwise erase it.
 */
interface IdInFilter<Row> {
  in(column: "id", values: string[]): PromiseLike<{ data: Row[] | null; error: unknown }>;
}

export async function fetchRowsByIds<Row extends { id: string }, Block = Row>(
  query: IdInFilter<Row>,
  ids: string[],
  // The identity default is why `Block` defaults to `Row`; the two are only
  // unrelated to the compiler inside this body, hence the one assertion.
  toBlock: (row: Row) => Block | null = (row) => row as unknown as Block,
): Promise<Map<string, Block>> {
  const map = new Map<string, Block>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) {
    const block = toBlock(row);
    if (block) map.set(row.id, block);
  }
  return map;
}

const blockItems = (block: ContentBlock): ItemRef[] => [
  ...picksOf(block),
  ...outfitsOf(block).flatMap((look) => look.pieces),
];

// The model can misquote an id, and Postgres fails the whole `.in("id", …)`
// batch (22P02) on a malformed uuid, so only uuid ids are queried.
export const idsOf = (blocks: ContentBlock[], type: ItemRef["type"]): string[] => [
  ...new Set(
    blocks
      .flatMap(blockItems)
      .filter((item) => item.type === type && isUuid(item.id))
      .map((item) => item.id),
  ),
];

/** An image-less product cannot be tried on, so no surface is handed one to offer. */
export const hasProductImage = (row: { image_paths?: string[] | null }): boolean =>
  typeof row.image_paths?.[0] === "string" && row.image_paths[0].length > 0;

export const supabaseAnswerRows: AnswerHydrator = async (
  client: DbClient,
  userId: string,
  blocks: ContentBlock[],
) => {
  const [products, wardrobe] = await Promise.all([
    fetchRowsByIds(
      client.from("products").select(PRODUCT_SELECT),
      idsOf(blocks, "product"),
      (row) => (hasProductImage(row) ? row : null),
    ),
    fetchRowsByIds(
      client.from("wardrobe_items").select(WARDROBE_SELECT).eq("user_id", userId),
      idsOf(blocks, "wardrobe"),
    ),
  ]);
  return { products, wardrobe };
};
