import { assertEquals } from "@std/assert";
import {
  type LineOutfit,
  lookLabel,
  outfitBubble,
  outfitTryonAction,
  outfitResultMessage,
  outfitMetaText,
  type OutfitPiece,
  resolveOutfitPieces,
} from "./outfit-card.ts";
import { CARD_COLOR, cornerTag } from "./card-kit.ts";
import { outfitTryonPostbackData } from "./postback.ts";
import type { LineProduct } from "./product-card.ts";
import type { LineWardrobeItem } from "./wardrobe-card.ts";

const LIFF = "https://liff.example";

const product = (id: string, price = 1280): LineProduct => ({
  id,
  name: `商品 ${id}`,
  price,
  imageUrl: `https://img.example/${id}.jpg`,
  storeName: "某店",
  purchaseUrl: null,
});

const wardrobe = (id: string): LineWardrobeItem => ({
  id,
  imageUrl: `https://sig.example/${id}.png`,
  garmentTypeLabel: "上衣",
  tags: ["白色"],
});

const p = (id: string, price?: number): OutfitPiece => ({ kind: "product", item: product(id, price) });
const w = (id: string): OutfitPiece => ({ kind: "wardrobe", item: wardrobe(id) });

const look = (pieces: OutfitPiece[], reason: string | null = "白襯衫配深藍直筒"): LineOutfit => ({
  title: "週末休閒",
  ...(reason === null ? {} : { reason }),
  pieces,
});

// deno-lint-ignore no-explicit-any
const overlayTexts = (bubble: any): string[] =>
  // deno-lint-ignore no-explicit-any
  bubble.hero.contents[1].contents.slice(0, -1).map((c: any) => c.text);

Deno.test("resolveOutfitPieces keeps the outfit's order and is null when any piece is missing", () => {
  const find = {
    product: (id: string) => (id === "p1" ? product("p1") : undefined),
    wardrobe: (id: string) => (id === "w1" ? wardrobe("w1") : undefined),
  };

  assertEquals(
    resolveOutfitPieces([{ type: "wardrobe", id: "w1" }, { type: "product", id: "p1" }], find),
    [w("w1"), p("p1")],
  );
  assertEquals(resolveOutfitPieces([{ type: "product", id: "p1" }, { type: "product", id: "gone" }], find), null);
});

Deno.test("the meta line counts what is left to buy, and never prices a wardrobe-only look", () => {
  assertEquals(outfitMetaText([p("p1", 1280), p("p2", 599), p("p3", 699)]), "3 件 · NT$ 2,578");
  assertEquals(outfitMetaText([w("w1"), p("p2", 1380), p("p3", 780)]), "再買 2 件 · NT$ 2,160");
  assertEquals(outfitMetaText([w("w1"), w("w2")]), "全部來自你的衣櫃");
});

Deno.test("the look label pads both numbers", () => {
  assertEquals(lookLabel(0, 2), "LOOK 01 / 02");
  assertEquals(lookLabel(2, 3), "LOOK 03 / 03");
});

Deno.test("a three-piece outfit is one large cell beside two stacked ones", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2"), p("p3")]), 0, 2, LIFF) as any;
  const collage = bubble.hero.contents[0];

  assertEquals(bubble.size, "mega");
  assertEquals(collage.layout, "horizontal");
  assertEquals(collage.spacing, "xs");
  assertEquals(collage.contents[0].flex, 2);
  assertEquals(collage.contents[0].contents[0].url, "https://img.example/p1.jpg");
  assertEquals(collage.contents[0].contents[0].aspectRatio, "4:9");
  assertEquals(collage.contents[1].layout, "vertical");
  assertEquals(collage.contents[1].flex, 1);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents[1].contents.map((c: any) => c.contents[0].url), [
    "https://img.example/p2.jpg",
    "https://img.example/p3.jpg",
  ]);
});

Deno.test("a two-piece outfit is two equal halves", () => {
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(look([p("p1"), p("p2")]), 0, 1, LIFF) as any).hero.contents[0];

  assertEquals(collage.contents.length, 2);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents.map((c: any) => c.contents[0].aspectRatio), ["1:3", "1:3"]);
});

Deno.test("a product cell opens its LIFF page; a wardrobe cell shows whole, tagged, and opens nothing", () => {
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(look([w("w1"), p("p2")]), 0, 1, LIFF) as any).hero.contents[0];
  const [wardrobeCell, productCell] = collage.contents;

  assertEquals(productCell.action, { type: "uri", label: "商品詳情", uri: `${LIFF}/product/p2` });
  assertEquals(productCell.contents[0].aspectMode, "cover");
  assertEquals(wardrobeCell.action, undefined);
  assertEquals(wardrobeCell.contents[0].aspectMode, "fit");
  assertEquals(wardrobeCell.contents[0].backgroundColor, CARD_COLOR.surfaceVariant);
  assertEquals(wardrobeCell.contents[1], cornerTag("你的衣櫃", "dark"));
});

Deno.test("the overlay reads look, title, reason, then the meta line, and ends on the try-on pill", () => {
  const outfit = look([p("p1", 1280), p("p2", 599)]);
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(outfit, 0, 2, LIFF) as any;
  const overlay = bubble.hero.contents[1].contents;

  assertEquals(overlayTexts(bubble), ["LOOK 01 / 02", "週末休閒", "白襯衫配深藍直筒", "2 件 · NT$ 1,879"]);
  assertEquals(overlay[1].size, "xl");
  assertEquals(overlay[2].maxLines, 2);
  assertEquals(overlay[3].color, CARD_COLOR.onImageFaint);
  const cta = overlay.at(-1);
  assertEquals(cta.contents[0].text, "✦ 試穿整套");
  assertEquals(cta.action, {
    type: "postback",
    label: "試穿整套",
    data: outfitTryonPostbackData({
      title: "週末休閒",
      pieces: [{ type: "product", id: "p1" }, { type: "product", id: "p2" }],
    }),
    displayText: "試穿「週末休閒」",
  });
  assertEquals(bubble.hero.action, undefined);
});

Deno.test("an outfit with no reason skips that line", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2")], null), 0, 1, LIFF) as any;

  assertEquals(overlayTexts(bubble), ["LOOK 01 / 01", "週末休閒", "2 件 · NT$ 2,560"]);
});

Deno.test("the result card leads with the try-on, then lists every piece", () => {
  // deno-lint-ignore no-explicit-any
  const message = outfitResultMessage("https://img.example/result.jpg", look([w("w1"), p("p2", 1380)]), LIFF) as any;
  const bubble = message.contents;

  assertEquals(message.altText, "為你試穿了「週末休閒」");
  assertEquals(bubble.hero.contents[0].url, "https://img.example/result.jpg");
  assertEquals(bubble.hero.contents[0].aspectRatio, "9:16");
  assertEquals(bubble.hero.action, { type: "uri", label: "看大圖", uri: "https://img.example/result.jpg" });
  // deno-lint-ignore no-explicit-any
  assertEquals(bubble.hero.contents[1].contents.map((c: any) => c.text), ["LOOK", "週末休閒"]);

  // deno-lint-ignore no-explicit-any
  const rows = bubble.body.contents.filter((c: any) => c.type === "box");
  assertEquals(rows.length, 2);
  assertEquals(rows[0].action, undefined);
  assertEquals(JSON.stringify(rows[0]).includes("你的衣櫃"), true);
  assertEquals(rows[1].action, { type: "uri", label: "商品詳情", uri: `${LIFF}/product/p2` });
  assertEquals(JSON.stringify(rows[1]).includes("$1,380"), true);
  // deno-lint-ignore no-explicit-any
  assertEquals(message.quickReply.items.map((i: any) => i.action.label), ["再配一套", "找類似的", "試我自己的衣服"]);
});

Deno.test("an over-long title is clamped in the try-on displayText and the result card altText", () => {
  const long: LineOutfit = { ...look([w("w1"), p("p2")]), title: "長".repeat(200) };
  const clamped = "長".repeat(12);

  // deno-lint-ignore no-explicit-any
  const action = outfitTryonAction(long) as any;
  assertEquals(action.displayText, `試穿「${clamped}」`);
  assertEquals(new URLSearchParams(action.data).get("t"), clamped);
  assertEquals(action.data.length <= 300, true);

  // deno-lint-ignore no-explicit-any
  const message = outfitResultMessage("https://img.example/result.jpg", long, LIFF) as any;
  assertEquals(message.altText, `為你試穿了「${clamped}」`);
});
