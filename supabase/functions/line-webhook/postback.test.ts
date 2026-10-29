import { assertEquals } from "@std/assert";
import {
  outfitTryonPostbackData,
  parsePostback,
  productTryonPostbackData,
  wardrobeTryonPostbackData,
} from "./postback.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const CID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const WID = "44444444-4444-4444-4444-444444444444";

Deno.test("what a product card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(productTryonPostbackData(PID, CID)), {
    kind: "product",
    productId: PID,
    colorId: CID,
  });
});

Deno.test("a product postback without a valid colour id is rejected", () => {
  assertEquals(parsePostback(`a=tryon_product&pid=${PID}`), null);
  assertEquals(parsePostback(`a=tryon_product&pid=${PID}&cid=nope`), null);
  assertEquals(parsePostback(`a=tryon_product&cid=${CID}`), null);
});

Deno.test("what a wardrobe card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(wardrobeTryonPostbackData(WID)), {
    kind: "wardrobe",
    wardrobeItemId: WID,
  });
});

Deno.test("the two kinds cannot be mistaken for each other", () => {
  assertEquals(parsePostback(`a=tryon_product&wid=${WID}`), null);
  assertEquals(parsePostback(`a=tryon_wardrobe&pid=${PID}`), null);
});

Deno.test("a card from before the rename no longer resolves", () => {
  // Deliberate: back-compat was declined, so cards already sent fall through
  // to the hint.
  assertEquals(parsePostback(`a=tryon&pid=${PID}`), null);
});

Deno.test("an unknown action is not ours to handle", () => {
  assertEquals(parsePostback(`a=save&pid=${PID}`), null);
  assertEquals(parsePostback(`pid=${PID}`), null);
  assertEquals(parsePostback(""), null);
});

Deno.test("an id Postgres would reject never reaches Postgres", () => {
  assertEquals(parsePostback("a=tryon_product&pid=not-a-uuid"), null);
  assertEquals(parsePostback("a=tryon_product&pid="), null);
  assertEquals(parsePostback("a=tryon_product"), null);
  assertEquals(parsePostback("a=tryon_wardrobe&wid=not-a-uuid"), null);
  assertEquals(parsePostback("a=tryon_wardrobe&wid="), null);
  assertEquals(parsePostback("a=tryon_wardrobe"), null);
});

Deno.test("a data field that is not even a string is not a postback", () => {
  assertEquals(parsePostback(undefined), null);
  assertEquals(parsePostback(null), null);
  assertEquals(parsePostback({ a: "tryon_product" }), null);
});

const P1 = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const P2 = "a1b2c3d4-e5f6-4789-8abc-def012345678";
const W1 = "44444444-4444-4444-4444-444444444444";

Deno.test("what an outfit card encodes is what the webhook reads back, in order", () => {
  const pieces = [
    { type: "product" as const, id: P1 },
    { type: "wardrobe" as const, id: W1 },
    { type: "product" as const, id: P2 },
  ];
  assertEquals(
    parsePostback(outfitTryonPostbackData(pieces)),
    { kind: "outfit", pieces },
  );
});

Deno.test("an outfit postback stays under LINE's 300-character data cap at its longest", () => {
  const data = outfitTryonPostbackData([
    { type: "product", id: P1 },
    { type: "wardrobe", id: W1 },
    { type: "product", id: P2 },
  ]);
  assertEquals(data.length <= 300, true);
});

Deno.test("an outfit postback with a count no outfit can have is not ours", () => {
  const encode = (ids: string[]) =>
    new URLSearchParams({
      a: "tryon_outfit",
      g: ids.map((id) => `p:${id}`).join(","),
    }).toString();

  assertEquals(parsePostback(encode([P1])), null);
  assertEquals(
    parsePostback(encode([P1, P2, W1, "c3d4e5f6-a7b8-4901-8cde-f01234567890"])),
    null,
  );
});

Deno.test("an outfit postback with a bad piece is not ours", () => {
  const raw = (g: string) =>
    new URLSearchParams({ a: "tryon_outfit", g }).toString();

  assertEquals(parsePostback(raw(`p:${P1},p:not-a-uuid`)), null);
  assertEquals(parsePostback(raw(`p:${P1},x:${P2}`)), null);
  assertEquals(parsePostback(raw(`p:${P1},${P2}`)), null);
});
