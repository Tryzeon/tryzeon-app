import { assertEquals } from "@std/assert";
import {
  collageOrder,
  type LineOutfit,
  outfitBubble,
  type OutfitPiece,
  outfitPieceRefs,
  outfitPurchase,
  outfitResultMessage,
  outfitTryonAction,
  resolveOutfitPieces,
} from "./outfit-card.ts";
import { CARD_COLOR, cornerTag, whitePill } from "./card-kit.ts";
import { outfitTryonPostbackData } from "./postback.ts";
import type { LineProduct } from "./product-card.ts";
import type { LineWardrobeItem } from "./wardrobe-card.ts";
import type { Enums } from "../_shared/database.types.ts";

const COLOR_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const LIFF = "https://liff.example";

type GarmentType = Enums<"garment_type">;

const product = (
  id: string,
  price = 1280,
  garmentType: GarmentType = "top",
): LineProduct => ({
  id,
  name: `商品 ${id}`,
  price,
  imageUrl: `https://img.example/${id}.jpg`,
  garmentType,
  storeName: "某店",
  purchaseUrl: null,
  color: { id: COLOR_ID, name: null },
});

const wardrobe = (
  id: string,
  garmentType: GarmentType = "top",
): LineWardrobeItem => ({
  id,
  imageUrl: `https://sig.example/${id}.png`,
  garmentType,
  garmentTypeLabel: "上衣",
  tags: ["白色"],
});

const p = (
  id: string,
  price?: number,
  garmentType?: GarmentType,
): OutfitPiece => ({
  kind: "product",
  item: product(id, price, garmentType),
});
const w = (id: string, garmentType?: GarmentType): OutfitPiece => ({
  kind: "wardrobe",
  item: wardrobe(id, garmentType),
});

const look = (
  pieces: OutfitPiece[],
  reason: string | null = "白襯衫配深藍直筒",
): LineOutfit => ({
  title: "週末休閒",
  ...(reason === null ? {} : { reason }),
  pieces,
});

// deno-lint-ignore no-explicit-any
const collageOf = (bubble: any) => bubble.hero.contents[0];

// deno-lint-ignore no-explicit-any
const overlayOf = (bubble: any) => bubble.hero.contents[2];

// deno-lint-ignore no-explicit-any
const bodyTexts = (bubble: any): string[] =>
  JSON.stringify(overlayOf(bubble)).match(/"text":"[^"]*"/g)!.map((t) =>
    JSON.parse(`{${t}}`).text
  );

// deno-lint-ignore no-explicit-any
const imagesOf = (node: any): any[] =>
  node.type === "image" ? [node] : (node.contents ?? []).flatMap(imagesOf);

Deno.test("resolveOutfitPieces keeps the outfit's order and is null when any piece is missing", () => {
  const find = {
    product: (id: string, _colorId: string | undefined) =>
      id === "p1" ? product("p1") : undefined,
    wardrobe: (id: string) => (id === "w1" ? wardrobe("w1") : undefined),
  };

  assertEquals(
    resolveOutfitPieces([{ type: "wardrobe", id: "w1" }, {
      type: "product",
      id: "p1",
    }], find),
    [w("w1"), p("p1")],
  );
  assertEquals(
    resolveOutfitPieces([{ type: "product", id: "p1" }, {
      type: "product",
      id: "gone",
    }], find),
    null,
  );
});

Deno.test("resolveOutfitPieces asks for each product in the colour its ref names", () => {
  const asked: Array<[string, string | undefined]> = [];
  resolveOutfitPieces(
    [{ type: "product", id: "p1", colorId: "c2" }, {
      type: "product",
      id: "p2",
    }],
    {
      product: (id, colorId) => {
        asked.push([id, colorId]);
        return product(id);
      },
      wardrobe: () => undefined,
    },
  );

  assertEquals(asked, [["p1", "c2"], ["p2", undefined]]);
});

Deno.test("outfitPieceRefs carries each product's colour and nothing on a wardrobe piece", () => {
  assertEquals(outfitPieceRefs([p("p1"), w("w1")]), [
    { type: "product", id: "p1", colorId: COLOR_ID },
    { type: "wardrobe", id: "w1" },
  ]);
});

Deno.test("the purchase counts and prices only the pieces left to buy", () => {
  assertEquals(outfitPurchase([p("p1", 1280), p("p2", 599)]), {
    count: 2,
    total: 1879,
  });
  assertEquals(outfitPurchase([w("w1"), p("p2", 1380), p("p3", 780)]), {
    count: 2,
    total: 2160,
  });
  assertEquals(outfitPurchase([w("w1"), w("w2")]), null);
});

Deno.test("a three-piece outfit is a 3:2 lead cell beside two stacked ones, 400px tall", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2"), p("p3")]), LIFF) as any;
  const collage = collageOf(bubble);

  assertEquals(bubble.size, "mega");
  assertEquals(bubble.body, undefined);
  assertEquals(bubble.footer, undefined);
  assertEquals(collage.layout, "horizontal");
  assertEquals(collage.spacing, "xs");
  assertEquals(collage.contents[0].flex, 3);
  assertEquals(
    collage.contents[0].contents[0].url,
    "https://img.example/p1.jpg",
  );
  assertEquals(collage.contents[0].contents[0].aspectRatio, "179:400");
  assertEquals(collage.contents[1].layout, "vertical");
  assertEquals(collage.contents[1].flex, 2);
  assertEquals(
    // deno-lint-ignore no-explicit-any
    collage.contents[1].contents.map((c: any) => c.contents[0].aspectRatio),
    ["119:199", "119:199"],
  );
  assertEquals(
    // deno-lint-ignore no-explicit-any
    collage.contents[1].contents.map((c: any) => c.contents[0].url),
    [
      "https://img.example/p2.jpg",
      "https://img.example/p3.jpg",
    ],
  );
});

Deno.test("a two-piece outfit is two equal halves", () => {
  const collage = collageOf(outfitBubble(look([p("p1"), p("p2")]), LIFF));

  assertEquals(collage.contents.length, 2);
  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents.map((c: any) => c.contents[0].aspectRatio), [
    "149:400",
    "149:400",
  ]);
});

Deno.test("every collage ratio is one LINE accepts: two positive integers, at most three times as tall as wide", () => {
  for (const pieces of [[p("p1"), p("p2")], [p("p1"), w("w2"), p("p3")]]) {
    for (const image of imagesOf(collageOf(outfitBubble(look(pieces), LIFF)))) {
      const match = /^(\d+):(\d+)$/.exec(image.aspectRatio);
      assertEquals(match !== null, true, image.aspectRatio);
      const [width, height] = [Number(match![1]), Number(match![2])];
      assertEquals(
        width > 0 && height > 0 && height <= 3 * width,
        true,
        image.aspectRatio,
      );
    }
  }
});

Deno.test("outerwear leads the collage and the rest keep their order; the try-on keeps the outfit's", () => {
  const outfit = look([
    p("top"),
    w("pants", "pants"),
    p("coat", 2480, "outerwear"),
  ]);
  const collage = collageOf(outfitBubble(outfit, LIFF));

  assertEquals(
    collage.contents[0].contents[0].url,
    "https://img.example/coat.jpg",
  );
  assertEquals(
    // deno-lint-ignore no-explicit-any
    collage.contents[1].contents.map((c: any) => c.contents[0].url),
    [
      "https://img.example/top.jpg",
      "https://sig.example/pants.png",
    ],
  );
  assertEquals(outfit.pieces.map((piece) => piece.item.id), [
    "top",
    "pants",
    "coat",
  ]);
});

Deno.test("collageOrder leaves a look with no outerwear, or already led by it, as it is", () => {
  const plain = [p("top"), p("skirt", 990, "skirt")];
  const led = [p("coat", 2480, "outerwear"), p("dress", 1980, "one_piece")];
  assertEquals(collageOrder(plain), plain);
  assertEquals(collageOrder(led), led);
});

Deno.test("a product cell opens its LIFF page, unpriced; a wardrobe cell fills over the warm backdrop, tagged 衣櫃, and opens nothing", () => {
  const collage = collageOf(outfitBubble(look([w("w1"), p("p2")]), LIFF));
  const [wardrobeCell, productCell] = collage.contents;

  assertEquals(productCell.action, {
    type: "uri",
    label: "商品詳情",
    uri: `${LIFF}/product/p2?color=${COLOR_ID}`,
  });
  assertEquals(productCell.contents.length, 1);
  assertEquals(productCell.contents[0].aspectMode, "cover");
  assertEquals(wardrobeCell.action, undefined);
  assertEquals(wardrobeCell.contents[0].aspectMode, "cover");
  assertEquals(
    wardrobeCell.contents[0].backgroundColor,
    CARD_COLOR.cutoutBackdrop,
  );
  assertEquals(wardrobeCell.contents[1], cornerTag("衣櫃"));
});

Deno.test("a look made only of owned pieces carries no cell tags", () => {
  const collage = collageOf(outfitBubble(look([w("w1"), w("w2")]), LIFF));

  // deno-lint-ignore no-explicit-any
  assertEquals(collage.contents.map((c: any) => c.contents.length), [1, 1]);
});

Deno.test("the overlay reads title, reason, then what to buy and its total beside the try-on pill", () => {
  const outfit = look([p("p1", 1280), p("p2", 599)]);
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(outfit, LIFF) as any;
  const overlay = overlayOf(bubble);
  const [title, reason, row] = overlay.contents;
  const [summary, cta] = row.contents;

  assertEquals(bodyTexts(bubble), [
    "週末休閒",
    "白襯衫配深藍直筒",
    "共 2 件",
    "NT$1,879",
    "✦ 試穿整套",
  ]);
  assertEquals(overlay.position, "absolute");
  assertEquals(overlay.paddingAll, "14px");
  assertEquals(bubble.hero.contents[1].height, "192px");
  assertEquals(title.size, "lg");
  assertEquals(title.weight, "bold");
  assertEquals(title.color, CARD_COLOR.onImage);
  assertEquals(title.maxLines, 1);
  assertEquals(reason.color, CARD_COLOR.onImageMuted);
  assertEquals(reason.wrap, true);
  assertEquals(reason.maxLines, 2);
  assertEquals(row.layout, "horizontal");
  assertEquals(summary.flex, 1);
  assertEquals(summary.contents[0].color, CARD_COLOR.onImageMuted);
  assertEquals(summary.contents[1].color, CARD_COLOR.onImage);
  assertEquals(
    cta,
    whitePill("✦ 試穿整套", outfitTryonAction(outfit), "regular"),
  );
  assertEquals(cta.action, {
    type: "postback",
    label: "試穿整套",
    data: outfitTryonPostbackData([
      { type: "product", id: "p1", colorId: COLOR_ID },
      { type: "product", id: "p2", colorId: COLOR_ID },
    ]),
    displayText: "試穿整套",
  });
});

Deno.test("a large total keeps the try-on pill whole beside a flexible summary", () => {
  const row = overlayOf(
    // deno-lint-ignore no-explicit-any
    outfitBubble(look([p("p1", 100000), p("p2", 23456)]), LIFF) as any,
  ).contents.at(-1);
  const [summary, cta] = row.contents;

  assertEquals(summary.contents[1].text, "NT$123,456");
  assertEquals(summary.flex, 1);
  assertEquals(cta.flex, 0);
});

Deno.test("a wardrobe-only look says so in white", () => {
  const summary =
    // deno-lint-ignore no-explicit-any
    overlayOf(outfitBubble(look([w("w1"), w("w2")]), LIFF) as any).contents.at(
      -1,
    ).contents[0];
  assertEquals(summary.contents, [{
    type: "text",
    text: "全部來自你的衣櫃",
    size: "sm",
    color: CARD_COLOR.onImage,
  }]);
});

Deno.test("an outfit with no reason skips that line, a mixed one counts what is left to buy, and a wardrobe-only one has no total", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = outfitBubble(look([p("p1"), p("p2")], null), LIFF) as any;
  // deno-lint-ignore no-explicit-any
  const mixed = outfitBubble(look([w("w1"), p("p2", 1280)]), LIFF) as any;
  // deno-lint-ignore no-explicit-any
  const ownOnly = outfitBubble(look([w("w1"), w("w2")]), LIFF) as any;

  assertEquals(bodyTexts(bubble), [
    "週末休閒",
    "共 2 件",
    "NT$2,560",
    "✦ 試穿整套",
  ]);
  assertEquals(bodyTexts(mixed).slice(-3), [
    "再買 1 件",
    "NT$1,280",
    "✦ 試穿整套",
  ]);
  assertEquals(bodyTexts(ownOnly).includes("全部來自你的衣櫃"), true);
  assertEquals(bodyTexts(ownOnly).some((t) => t.startsWith("NT$")), false);
});

Deno.test("the result card leads with the try-on, then lists every piece", () => {
  const message = outfitResultMessage(
    "https://img.example/result.jpg",
    [w("w1"), p("p2", 1380)],
    LIFF,
    // deno-lint-ignore no-explicit-any
  ) as any;
  const bubble = message.contents;

  assertEquals(message.altText, "為你試穿了整套穿搭");
  assertEquals(bubble.hero.url, "https://img.example/result.jpg");
  assertEquals(bubble.hero.aspectRatio, "9:16");
  assertEquals(bubble.hero.action, {
    type: "uri",
    label: "看大圖",
    uri: "https://img.example/result.jpg",
  });

  // deno-lint-ignore no-explicit-any
  const rows = bubble.body.contents.filter((c: any) => c.type === "box");
  assertEquals(rows.length, 2);
  assertEquals(rows[0].action, undefined);
  assertEquals(JSON.stringify(rows[0]).includes("你的衣櫃"), true);
  assertEquals(rows[1].action, {
    type: "uri",
    label: "商品詳情",
    uri: `${LIFF}/product/p2?color=${COLOR_ID}`,
  });
  assertEquals(JSON.stringify(rows[1]).includes("NT$1,380"), true);
  // deno-lint-ignore no-explicit-any
  assertEquals(message.quickReply.items.map((i: any) => i.action.label), [
    "再配一套",
    "找類似的",
    "試我自己的衣服",
  ]);
});
