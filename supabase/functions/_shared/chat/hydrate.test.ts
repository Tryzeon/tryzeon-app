import { assertEquals } from "@std/assert";
import { hasProductImage, idsOf, supabaseColorNames } from "./hydrate.ts";
import type { AnswerBlock } from "./types.ts";
import type { DbClient } from "../supabase.ts";

const A = "f8f49d33-e34a-4121-a6b9-f654e0614971";
const B = "0b2c3d4e-5f60-4718-8293-a4b5c6d7e8f9";
const C = "a1b2c3d4-e5f6-4789-8abc-def012345678";

const pick = (type: "product" | "wardrobe", id: string) => ({ type, id });

Deno.test("idsOf collects uuid ids of one type from picks and outfits, once each", () => {
  const blocks: AnswerBlock[] = [
    { type: "text", text: "x" },
    {
      type: "picks",
      picks: [pick("product", A), pick("wardrobe", B), pick("product", A)],
    },
    {
      type: "outfits",
      outfits: [{
        title: "L",
        pieces: [pick("product", C), pick("wardrobe", B)],
      }],
    },
  ];
  assertEquals(idsOf(blocks, "product"), [A, C]);
  assertEquals(idsOf(blocks, "wardrobe"), [B]);
});

Deno.test("idsOf skips ids that are not uuids", () => {
  const blocks: AnswerBlock[] = [{
    type: "picks",
    picks: [pick("product", "p1"), pick("product", A)],
  }];
  assertEquals(idsOf(blocks, "product"), [A]);
});

Deno.test("hasProductImage needs a non-empty first image path", () => {
  const color = (image_paths: string[]) => ({
    id: "c1",
    name: null,
    image_paths,
    position: 0,
  });
  assertEquals(
    hasProductImage({ product_colors: [color(["stores/s1/p1.jpg"])] }),
    true,
  );
  for (
    const product_colors of [[], null, [color([])], [color([""])], undefined]
  ) {
    assertEquals(hasProductImage({ product_colors }), false);
  }
});

function colorClient(data: unknown[]) {
  const calls: unknown[][] = [];
  const client = {
    from: (table: string) => ({
      select: (columns: string) => ({
        in: (column: string, values: string[]) => {
          calls.push([table, columns, column, values]);
          return Promise.resolve({ data, error: null });
        },
      }),
    }),
  } as unknown as DbClient;
  return { client, calls };
}

Deno.test("supabaseColorNames groups colours by product and skips unnamed ones", async () => {
  const { client, calls } = colorClient([
    { id: "c1", product_id: A, name: "黑" },
    { id: "c2", product_id: A, name: "白" },
    { id: "c3", product_id: A, name: null },
    { id: "c4", product_id: B, name: "紅" },
  ]);
  const colors = await supabaseColorNames(client, [A, B]);
  assertEquals(calls, [[
    "product_colors",
    "id, product_id, name",
    "product_id",
    [A, B],
  ]]);
  assertEquals(
    colors.get(A),
    [{ id: "c1", name: "黑" }, { id: "c2", name: "白" }],
  );
  assertEquals(colors.get(B), [{ id: "c4", name: "紅" }]);
});

Deno.test("supabaseColorNames does not query without ids", async () => {
  const { client, calls } = colorClient([]);
  assertEquals((await supabaseColorNames(client, [])).size, 0);
  assertEquals(calls, []);
});
