import { assertEquals } from "@std/assert";
import { idsOf } from "./hydrate.ts";

const A = "f8f49d33-e34a-4121-a6b9-f654e0614971";
const B = "0b2c3d4e-5f60-4718-8293-a4b5c6d7e8f9";
const C = "a1b2c3d4-e5f6-4789-8abc-def012345678";

const pick = (type: "product" | "wardrobe", id: string) => ({ type, id });

Deno.test("idsOf collects uuid ids of one type from picks and outfits, once each", () => {
  const blocks = [
    { type: "text", text: "x" },
    { type: "picks", picks: [pick("product", A), pick("wardrobe", B), pick("product", A)] },
    {
      type: "outfits",
      outfits: [{ title: "L", pieces: [pick("product", C), pick("wardrobe", B)] }],
    },
  ];
  assertEquals(idsOf(blocks, "product"), [A, C]);
  assertEquals(idsOf(blocks, "wardrobe"), [B]);
});

Deno.test("idsOf skips ids that are not uuids", () => {
  const blocks = [{ type: "picks", picks: [pick("product", "p1"), pick("product", A)] }];
  assertEquals(idsOf(blocks, "product"), [A]);
});

Deno.test("idsOf skips the ids of a look that cannot render", () => {
  const blocks = [{
    type: "outfits",
    outfits: [
      { title: "single", pieces: [pick("product", A)] },
      { title: "", pieces: [pick("product", B), pick("product", C)] },
      { title: "four", pieces: [A, B, C, "d1b2c3d4-e5f6-4789-8abc-def012345678"].map((id) => pick("product", id)) },
    ],
  }];
  assertEquals(idsOf(blocks, "product"), []);
});
