import { assertEquals } from "@std/assert";
import {
  clampOutfitTitle,
  MAX_OUTFIT_TITLE_CHARS,
  outfitTryonPostbackData,
  parsePostback,
  productTryonPostbackData,
  wardrobeTryonPostbackData,
} from "./postback.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const WID = "44444444-4444-4444-4444-444444444444";

Deno.test("what a product card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(productTryonPostbackData(PID)), {
    kind: "product",
    productId: PID,
  });
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
    parsePostback(outfitTryonPostbackData({ title: "週末休閒", pieces })),
    {
      kind: "outfit",
      pieces,
      title: "週末休閒",
    },
  );
});

Deno.test("an outfit postback stays under LINE's 300-character data cap at its longest", () => {
  const data = outfitTryonPostbackData({
    title: "一二三四五六七八九十甲乙",
    pieces: [{ type: "product", id: P1 }, { type: "wardrobe", id: W1 }, {
      type: "product",
      id: P2,
    }],
  });
  assertEquals(data.length <= 300, true);
});

Deno.test("an outfit postback with a count no outfit can have is not ours", () => {
  const encode = (ids: string[]) =>
    new URLSearchParams({
      a: "tryon_outfit",
      g: ids.map((id) => `p:${id}`).join(","),
      t: "A",
    }).toString();

  assertEquals(parsePostback(encode([P1])), null);
  assertEquals(
    parsePostback(encode([P1, P2, W1, "c3d4e5f6-a7b8-4901-8cde-f01234567890"])),
    null,
  );
});

Deno.test("an outfit postback with a bad piece or no title is not ours", () => {
  const raw = (g: string, t?: string) =>
    new URLSearchParams({
      a: "tryon_outfit",
      g,
      ...(t === undefined ? {} : { t }),
    }).toString();

  assertEquals(parsePostback(raw(`p:${P1},p:not-a-uuid`, "A")), null);
  assertEquals(parsePostback(raw(`p:${P1},x:${P2}`, "A")), null);
  assertEquals(parsePostback(raw(`p:${P1},${P2}`, "A")), null);
  assertEquals(parsePostback(raw(`p:${P1},p:${P2}`)), null);
  assertEquals(parsePostback(raw(`p:${P1},p:${P2}`, "   ")), null);
});

Deno.test("a tampered outfit title is clamped before it can reach a displayText", () => {
  const data = new URLSearchParams({
    a: "tryon_outfit",
    g: `p:${P1},p:${P2}`,
    t: "長".repeat(200),
  }).toString();
  // deno-lint-ignore no-explicit-any
  assertEquals((parsePostback(data) as any).title, "長".repeat(12));
});

Deno.test("an over-long outfit title is clamped by code point in the postback data", () => {
  const pieces = [{ type: "product" as const, id: P1 }, {
    type: "product" as const,
    id: P2,
  }];
  const data = outfitTryonPostbackData({ title: "長".repeat(200), pieces });
  assertEquals(
    new URLSearchParams(data).get("t"),
    "長".repeat(MAX_OUTFIT_TITLE_CHARS),
  );
  assertEquals(data.length <= 300, true);
});

Deno.test("clampOutfitTitle trims what the slice leaves and never splits a surrogate pair", () => {
  assertEquals(
    clampOutfitTitle("一二三四五六七八九十甲 乙丙"),
    "一二三四五六七八九十甲",
  );
  assertEquals(
    clampOutfitTitle("😀".repeat(20)),
    "😀".repeat(MAX_OUTFIT_TITLE_CHARS),
  );
});

Deno.test("an outfit postback of three pieces and a 12-emoji title stays within the 300-character cap", () => {
  const data = outfitTryonPostbackData({
    title: "😀".repeat(12),
    pieces: [{ type: "product", id: P1 }, { type: "wardrobe", id: W1 }, {
      type: "product",
      id: P2,
    }],
  });
  assertEquals(data.length <= 300, true);
});
