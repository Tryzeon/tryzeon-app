import { assertEquals } from "@std/assert";
import {
  hasProductImage,
  idsOf,
  namedColors,
  supabaseAnswerRows,
} from "./hydrate.ts";
import type { DbClient } from "../supabase.ts";
import type { AnswerBlock } from "./types.ts";

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

Deno.test("namedColors keeps each product's named colours and drops a product without one", () => {
  const colors = namedColors(
    new Map([
      [A, [{ id: "c1", name: "黑" }, { id: "c2", name: null }, {
        id: "c3",
        name: "白",
      }]],
      [B, [{ id: "c4", name: null }]],
    ]),
    (product) => product,
  );
  assertEquals(
    colors,
    new Map([[A, [{ id: "c1", name: "黑" }, { id: "c3", name: "白" }]]]),
  );
});

Deno.test("supabaseAnswerRows names the colours of the products it hydrated", async () => {
  const product = {
    id: A,
    product_colors: [
      { id: "c1", name: "黑", image_paths: ["k1"], position: 0 },
      { id: "c2", name: null, image_paths: ["k2"], position: 1 },
    ],
  };
  const query = {
    order: () => query,
    eq: () => query,
    in: (_column: string, ids: string[]) =>
      Promise.resolve({ data: ids.length > 0 ? [product] : [], error: null }),
  };
  const client = {
    from: () => ({ select: () => query }),
  } as unknown as DbClient;

  const rows = await supabaseAnswerRows(client, "u1", [
    { type: "picks", picks: [pick("product", A)] },
  ]);

  assertEquals(rows.colors, new Map([[A, [{ id: "c1", name: "黑" }]]]));
});
