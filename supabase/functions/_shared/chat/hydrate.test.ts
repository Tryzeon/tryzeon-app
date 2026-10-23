import { assertEquals } from "@std/assert";
import { hasProductImage, idsOf } from "./hydrate.ts";
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
  assertEquals(hasProductImage({ image_paths: ["stores/s1/p1.jpg"] }), true);
  for (const image_paths of [[], null, [""], undefined]) {
    assertEquals(hasProductImage({ image_paths }), false);
  }
});
