import { assertEquals } from "@std/assert";
import {
  collageOrder,
  type LineOutfit,
  outfitBubble,
  outfitPurchase,
  outfitTryonAction,
  outfitResultMessage,
  type OutfitPiece,
  resolveOutfitPieces,
} from "./outfit-card.ts";
import { CARD_COLOR, cornerTag } from "./card-kit.ts";
import { outfitTryonPostbackData } from "./postback.ts";
import type { LineProduct } from "./product-card.ts";
import type { LineWardrobeItem } from "./wardrobe-card.ts";
import type { Enums } from "../_shared/database.types.ts";

const LIFF = "https://liff.example";

type GarmentType = Enums<"garment_type">;

const product = (id: string, price = 1280, garmentType: GarmentType = "top"): LineProduct => ({
  id,
  name: `商品 ${id}`,
  price,
  imageUrl: `https://img.example/${id}.jpg`,
  garmentType,
  storeName: "某店",
  purchaseUrl: null,
});

const wardrobe = (id: string, garmentType: GarmentType = "top"): LineWardrobeItem => ({
  id,
  imageUrl: `https://sig.example/${id}.png`,
  garmentType,
  garmentTypeLabel: "上衣",
  tags: ["白色"],
});

const p = (id: string, price?: number, garmentType?: GarmentType): OutfitPiece => ({
  kind: "product",
  item: product(id, price, garmentType),
});
const w = (id: string, garmentType?: GarmentType): OutfitPiece => ({ kind: "wardrobe", item: wardrobe(id, garmentType) });

const look = (pieces: OutfitPiece[], reason: string | null = "白襯衫配深藍直筒"): LineOutfit => ({
  title: "週末休閒",
  ...(reason === null ? {} : { reason }),
  pieces,
});

// deno-lint-ignore no-explicit-any
const bodyTexts = (bubble: any): string[] =>
  JSON.stringify([bubble.body, bubble.footer]).match(/"text":"[^"]*"/g)!.map((t) => JSON.parse(`{${t}}`).text);

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

Deno.test("the purchase counts and prices only the pieces left to buy", () => {
  assertEquals(outfitPurchase([p("p1", 1280), p("p2", 599)]), { count: 2, total: 1879 });
  assertEquals(outfitPurchase([w("w1"), p("p2", 1380), p("p3", 780)]), { count: 2, total: 2160 });
  assertEquals(outfitPurchase([w("w1"), w("w2")]), null);
});

Deno.test("a three-piece outfit is a 2:1 lead cell beside two stacked ones, all 3:4", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2"), p("p3")]), LIFF) as any;
  const collage = bubble.hero;

  assertEquals(bubble.size, "mega");
  assertEquals(collage.layout, "horizontal");
  assertEquals(collage.spacing, "xs");
  assertEquals(collage.contents[0].flex, 2);
  assertEquals(collage.contents[0].contents[0].url, "https://img.example/p1.jpg");
  assertEquals(collage.contents[0].contents[0].aspectRatio, "149:198");
  assertEquals(collage.contents[1].layout, "vertical");
  assertEquals(collage.contents[1].flex, 1);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents[1].contents.map((c: any) => c.contents[0].aspectRatio), ["298:393", "298:393"]);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents[1].contents.map((c: any) => c.contents[0].url), [
    "https://img.example/p2.jpg",
    "https://img.example/p3.jpg",
  ]);
});

Deno.test("a two-piece outfit is two equal halves", () => {
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(look([p("p1"), p("p2")]), LIFF) as any).hero;

  assertEquals(collage.contents.length, 2);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents.map((c: any) => c.contents[0].aspectRatio), ["149:264", "149:264"]);
});

Deno.test("outerwear leads the collage and the rest keep their order; the try-on keeps the outfit's", () => {
  const outfit = look([p("top"), w("pants", "pants"), p("coat", 2480, "outerwear")]);
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(outfit, LIFF) as any).hero;

  assertEquals(collage.contents[0].contents[0].url, "https://img.example/coat.jpg");
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents[1].contents.map((c: any) => c.contents[0].url), [
    "https://img.example/top.jpg",
    "https://sig.example/pants.png",
  ]);
  assertEquals(outfit.pieces.map((piece) => piece.item.id), ["top", "pants", "coat"]);
});

Deno.test("collageOrder leaves a look with no outerwear, or already led by it, as it is", () => {
  const plain = [p("top"), p("skirt", 990, "skirt")];
  const led = [p("coat", 2480, "outerwear"), p("dress", 1980, "one_piece")];
  assertEquals(collageOrder(plain), plain);
  assertEquals(collageOrder(led), led);
});

Deno.test("a product cell opens its LIFF page, unpriced; a wardrobe cell keeps its cutout whole, tagged, and opens nothing", () => {
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(look([w("w1"), p("p2")]), LIFF) as any).hero;
  const [wardrobeCell, productCell] = collage.contents;

  assertEquals(productCell.action, { type: "uri", label: "商品詳情", uri: `${LIFF}/product/p2` });
  assertEquals(productCell.contents.length, 1);
  assertEquals(productCell.contents[0].aspectMode, "cover");
  assertEquals(wardrobeCell.action, undefined);
  assertEquals(wardrobeCell.contents[0].aspectMode, "fit");
  assertEquals(wardrobeCell.contents[0].backgroundColor, CARD_COLOR.surfaceVariant);
  assertEquals(wardrobeCell.contents[1], cornerTag("你的衣櫃"));
});

Deno.test("a look made only of owned pieces carries no cell tags", () => {
  // deno-lint-ignore no-explicit-any
  const collage = (outfitBubble(look([w("w1"), w("w2")]), LIFF) as any).hero;

  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents.map((c: any) => c.contents.length), [1, 1]);
});

Deno.test("the body reads title, reason, then what to buy and its total beside the try-on button", () => {
  const outfit = look([p("p1", 1280), p("p2", 599)]);
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(outfit, LIFF) as any;
  const [title, reason] = bubble.body.contents;
  const [rule, row] = bubble.footer.contents;
  const cta = row.contents.at(-1);

  assertEquals(bodyTexts(bubble), ["週末休閒", "白襯衫配深藍直筒", "共 2 件", "NT$1,879", "✦ 試穿整套"]);
  assertEquals(rule, { type: "separator", color: CARD_COLOR.outline });
  assertEquals(row.layout, "horizontal");
  assertEquals(title.size, "lg");
  assertEquals(title.maxLines, 1);
  assertEquals(reason.color, CARD_COLOR.mutedText);
  assertEquals(reason.maxLines, 2);
  assertEquals(cta.backgroundColor, CARD_COLOR.primary);
  assertEquals(cta.flex, 0);
  assertEquals(cta.action, {
    type: "postback",
    label: "試穿整套",
    data: outfitTryonPostbackData({
      title: "週末休閒",
      pieces: [{ type: "product", id: "p1" }, { type: "product", id: "p2" }],
    }),
    displayText: "試穿「週末休閒」",
  });
  assertEquals(bubble.styles.body.backgroundColor, CARD_COLOR.surface);
  assertEquals(bubble.styles.footer.backgroundColor, CARD_COLOR.surface);
});

Deno.test("an outfit with no reason skips that line, a mixed one counts what is left to buy, and a wardrobe-only one has no total", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2")], null), LIFF) as any;
  // deno-lint-ignore no-explicit-any
  const mixed = outfitBubble(look([w("w1"), p("p2", 1280)]), LIFF) as any;
  // deno-lint-ignore no-explicit-any
  const ownOnly = outfitBubble(look([w("w1"), w("w2")]), LIFF) as any;

  assertEquals(bodyTexts(bubble), ["週末休閒", "共 2 件", "NT$2,560", "✦ 試穿整套"]);
  assertEquals(bodyTexts(mixed).slice(-3), ["再買 1 件", "NT$1,280", "✦ 試穿整套"]);
  assertEquals(bodyTexts(ownOnly).includes("全部來自你的衣櫃"), true);
  assertEquals(bodyTexts(ownOnly).some((t) => t.startsWith("NT$")), false);
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
  assertEquals(bubble.hero.contents[1].contents.map((c: any) => c.text), ["週末休閒"]);

  // deno-lint-ignore no-explicit-any
  const rows = bubble.body.contents.filter((c: any) => c.type === "box");
  assertEquals(rows.length, 2);
  assertEquals(rows[0].action, undefined);
  assertEquals(JSON.stringify(rows[0]).includes("你的衣櫃"), true);
  assertEquals(rows[1].action, { type: "uri", label: "商品詳情", uri: `${LIFF}/product/p2` });
  assertEquals(JSON.stringify(rows[1]).includes("NT$1,380"), true);
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
