import { assertEquals } from "@std/assert";
import { renderAnswer } from "./chat-render.ts";
import { chatErrorMessage } from "./messages.ts";
import type { AnswerItems, ContentBlock } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";
import { CARD_COLOR, cornerTag, detailDot } from "./card-kit.ts";
import type { LineWardrobeItem } from "./wardrobe-card.ts";
import { productTryonPostbackData, wardrobeTryonPostbackData } from "./postback.ts";

const product = (id: string, over: Partial<LineProduct> = {}): LineProduct => ({
  id,
  name: `商品 ${id}`,
  price: 1200,
  imageUrl: `https://img.example/${id}.jpg`,
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

type Card =
  | { type: "product"; item: LineProduct; highlight?: string }
  | { type: "wardrobe"; item: LineWardrobeItem };

type Look = { title: string; reason?: string; cards: Card[] };

type Part =
  | { type: "text"; text: string }
  | { type: "row"; cards: Card[] }
  | { type: "outfits"; looks: Look[] };

const LIFF = "https://liff.example";

const text = (t: string): Part => ({ type: "text", text: t });
const card = (p: LineProduct, highlight?: string): Card => ({
  type: "product",
  item: p,
  ...(highlight === undefined ? {} : { highlight }),
});
const row = (...cards: Card[]): Part => ({ type: "row", cards });
const looks = (...l: Look[]): Part => ({ type: "outfits", looks: l });
const look = (title: string, ...cards: Card[]): Look => ({ title, reason: "好搭", cards });

/** Splits fixture parts into what the core hands over: rows of id refs plus the rows they name. */
function render(parts: Part[]): object[] {
  const items: AnswerItems = { products: {}, wardrobe: {} };
  const ref = (c: Card) => {
    (c.type === "product" ? items.products : items.wardrobe)[c.item.id] = c.item;
    return {
      type: c.type,
      id: c.item.id,
      ...(c.type === "product" && c.highlight ? { highlight: c.highlight } : {}),
    };
  };
  const content: ContentBlock[] = parts.map((part) => {
    if (part.type === "text") return part;
    if (part.type === "row") return { type: "picks", picks: part.cards.map(ref) };
    return {
      type: "outfits",
      outfits: part.looks.map((l) => ({
        title: l.title,
        ...(l.reason ? { reason: l.reason } : {}),
        pieces: l.cards.map((c) => ({ type: c.type, id: ref(c).id })),
      })),
    };
  });
  return renderAnswer(content, items, LIFF);
}

// deno-lint-ignore no-explicit-any
const ctaOf = (bubble: any) => bubble.hero.contents[1].contents.at(-1);

// deno-lint-ignore no-explicit-any
const badgesOf = (bubble: any) => bubble.hero.contents.slice(2);

// deno-lint-ignore no-explicit-any
const tryonIdsOf = (message: any) => bubbles(message).map((b: any) => ctaOf(b).action.data);

// deno-lint-ignore no-explicit-any
const bubbles = (message: any) => message.contents.contents as any[];

const wardrobeItem = (
  id: string,
  over: Partial<LineWardrobeItem> = {},
): LineWardrobeItem => ({
  id,
  imageUrl: `https://sig.example/${id}.png?token=abc`,
  garmentTypeLabel: "上衣",
  tags: ["寬鬆"],
  ...over,
});

const wardrobeCard = (w: LineWardrobeItem): Card => ({ type: "wardrobe", item: w });

Deno.test("a text-only answer is a single text message", () => {
  const out = render([text("你想找什麼樣的衣服？")]);
  assertEquals(out, [{ type: "text", text: "你想找什麼樣的衣服？" }]);
});

Deno.test("adjacent text blocks merge into one message", () => {
  const out = render([text("第一句"), text("第二句"), row(card(product("p1")))]);

  assertEquals(out.length, 2);
  assertEquals(out[0], { type: "text", text: "第一句\n第二句" });
});

Deno.test("an empty answer degrades to text rather than an empty send", () => {
  const out = render([]);
  assertEquals(out.length, 1);
  assertEquals((out[0] as { type: string }).type, "text");
});

Deno.test("every product card offers a try-on, keyed by its own id", () => {
  const out = render([row(card(product("p1")), card(product("p2")))]);
  const [first, second] = bubbles(out[0]);

  assertEquals(ctaOf(first).action, {
    type: "postback",
    label: "試穿",
    data: productTryonPostbackData("p1"),
    displayText: "試穿「商品 p1」",
  });
  assertEquals(ctaOf(first).contents[0].text, "✦ 試穿");
  assertEquals(ctaOf(second).action.data, productTryonPostbackData("p2"));
});

Deno.test("an over-long product name is clamped in the postback displayText", () => {
  const longName = "衣".repeat(60);
  const [bubble] = bubbles(render([row(card(product("p1", { name: longName })))])[0]);

  const displayText = ctaOf(bubble).action.displayText as string;
  assertEquals(displayText.length <= 300, true);
  assertEquals(displayText, `試穿「${"衣".repeat(40)}…」`);
});

Deno.test("a product card opens its LIFF product page from the photo, with no footer and no purchase", () => {
  const [bubble] = bubbles(
    render([row(card(product("p1", { purchaseUrl: "https://shop.example/p1" })))])[0],
  );

  assertEquals(bubble.hero.action, { type: "uri", label: "商品詳情", uri: `${LIFF}/product/p1` });
  assertEquals(bubble.footer, undefined);
  assertEquals(JSON.stringify(bubble).includes("shop.example"), false);
});

Deno.test("a product card lays its details and try-on over a 4:5 photo", () => {
  const [bubble] = bubbles(render([row(card(product("p1")))])[0]);

  assertEquals(bubble.body, undefined);
  assertEquals(bubble.hero.contents[0].url, "https://img.example/p1.jpg");
  assertEquals(bubble.hero.contents[0].aspectRatio, "4:5");
  assertEquals(bubble.hero.contents[0].aspectMode, "cover");
  assertEquals(
    // deno-lint-ignore no-explicit-any
    bubble.hero.contents[1].contents.slice(0, 3).map((c: any) => c.text ?? c.contents.map((s: any) => s.text).join("")),
    ["某店", "商品 p1", "NT$ 1,200"],
  );
});

Deno.test("a highlight rides the photo's top-left corner, and only when there is one", () => {
  const [withHighlight, without] = bubbles(
    render([row(card(product("p1"), "顯瘦直筒"), card(product("p2")))])[0],
  );

  assertEquals(badgesOf(withHighlight), [cornerTag("顯瘦直筒", "light"), detailDot()]);
  assertEquals(badgesOf(without), [detailDot()]);
});

const chipActions = (message: object): object[] =>
  // deno-lint-ignore no-explicit-any
  ((message as any).quickReply?.items ?? []).map((i: any) => i.action);

const NARROW_CHIPS = [
  { type: "message", label: "便宜一點的", text: "有便宜一點的嗎" },
  { type: "message", label: "換個風格", text: "換個風格看看" },
  { type: "message", label: "幫我配整套", text: "幫我配一整套穿搭" },
];

Deno.test("an answer with products offers ways to narrow it", () => {
  const out = render([text("為你找到"), row(card(product("p1")))]);

  // Only the last message carries them: LINE does not document which one wins
  // when several in one send do, so the design never creates that situation.
  assertEquals(chipActions(out[0]), []);
  assertEquals(chipActions(out.at(-1)!), NARROW_CHIPS);
});

Deno.test("a follow-up question is left alone", () => {
  // A chip here pushes the sender away from the one thing that would help:
  // their own answer.
  const out = render([text("你想找什麼場合穿的？")]);

  assertEquals(chipActions(out[0]), []);
});

Deno.test("the chips survive the fold that drops messages", () => {
  // 49 cards is one text message plus five 12-per-carousel chunks (MAX_BUBBLES):
  // six messages, one over MAX_LINE_MESSAGES, so the slice truly drops the last
  // carousel. A chip attached before that slice would go down with it.
  const blocks = [
    text("找到好多"),
    row(...Array.from({ length: 49 }, (_, i) => card(product(`p${i}`)))),
  ];

  const out = render(blocks);

  assertEquals(out.length, 5);
  assertEquals(chipActions(out.at(-1)!), NARROW_CHIPS);
});

Deno.test("a wardrobe card shows its photo whole, on a pinned light surface, with nothing to open", () => {
  const out = render([text("你衣櫃裡這件可以"), row(wardrobeCard(wardrobeItem("w1")))]);

  assertEquals(out.length, 2);
  const [bubble] = bubbles(out[1]);
  const photo = bubble.hero.contents[0];
  assertEquals(photo.url, "https://sig.example/w1.png?token=abc");
  // LINE accepts only `cover` and `fit` here and 400s the whole send otherwise.
  assertEquals(photo.aspectMode, "fit");
  assertEquals(photo.aspectRatio, "4:5");
  assertEquals(photo.backgroundColor, CARD_COLOR.surfaceVariant);
  assertEquals(bubble.hero.action, undefined);
  assertEquals(bubble.footer, undefined);
  assertEquals(badgesOf(bubble), [cornerTag("你的衣櫃", "dark")]);
  assertEquals(ctaOf(bubble).contents[0].text, "✦ 試穿");
});

Deno.test("the carousel altText names what is actually in it", () => {
  const alt = (cards: Card[]) =>
    // deno-lint-ignore no-explicit-any
    (render([row(...cards)]).at(-1) as any).altText;

  assertEquals(alt([card(product("p1"))]), "為你找到 1 件商品");
  assertEquals(alt([wardrobeCard(wardrobeItem("w1"))]), "你衣櫃裡的 1 件");
  assertEquals(
    alt([card(product("p1")), wardrobeCard(wardrobeItem("w1"))]),
    "為你找到 2 件",
  );
});

Deno.test("a wardrobe-only answer offers no shopping chips", () => {
  const out = render([row(wardrobeCard(wardrobeItem("w1")))]);

  // deno-lint-ignore no-explicit-any
  assertEquals((out.at(-1) as any).quickReply, undefined);
});

Deno.test("a wardrobe card offers a try-on keyed by its own id", () => {
  const out = render([row(wardrobeCard(wardrobeItem("44444444-4444-4444-4444-444444444444")))]);
  // deno-lint-ignore no-explicit-any
  const bubble = bubbles(out[0])[0] as any;
  const button = ctaOf(bubble);

  assertEquals(button.action.type, "postback");
  assertEquals(
    button.action.data,
    wardrobeTryonPostbackData("44444444-4444-4444-4444-444444444444"),
  );
  assertEquals(button.action.displayText, "試穿「你的上衣」");
});

Deno.test("the others bucket's card button reads 單品, not 其他", () => {
  // 「試穿「你的其他」」 is broken Chinese, and `others` is not a rare code.
  const out = render([row(wardrobeCard(wardrobeItem("w1", { garmentTypeLabel: "其他" })))]);
  // deno-lint-ignore no-explicit-any
  const bubble = bubbles(out[0])[0] as any;

  assertEquals(ctaOf(bubble).action.displayText, "試穿「你的單品」");
});

Deno.test("a row's picks share one carousel", () => {
  const out = render([text("為你找到這幾件"), row(card(product("p1")), card(product("p2")))]);

  assertEquals(out.length, 2);
  assertEquals(out[0], { type: "text", text: "為你找到這幾件" });
  assertEquals(bubbles(out[1]).length, 2);
});

Deno.test("adjacent rows stay separate carousels", () => {
  const out = render([row(card(product("p1"))), row(card(product("p2")), card(product("p3")))]);

  assertEquals(out.length, 2);
  assertEquals(tryonIdsOf(out[0]), [productTryonPostbackData("p1")]);
  assertEquals(tryonIdsOf(out[1]), [productTryonPostbackData("p2"), productTryonPostbackData("p3")]);
});

Deno.test("an outfit that fits keeps its interleaving", () => {
  const out = render([
    text("這套清爽"),
    row(card(product("p1"))),
    text("下面配寬褲"),
    row(card(product("p2"))),
  ]);

  assertEquals(out.map((m) => (m as { type: string }).type), ["text", "flex", "text", "flex"]);
});

Deno.test("more sections than LINE allows fold the prose to the top and keep every row", () => {
  const out = render([
    text("這套清爽"),
    row(card(product("p1"))),
    text("下面配寬褲"),
    row(card(product("p2"))),
    text("早晚涼加外套"),
    row(card(product("p3"))),
  ]);

  assertEquals(out.length, 4);
  assertEquals(out[0], { type: "text", text: "這套清爽\n下面配寬褲\n早晚涼加外套" });
  assertEquals(tryonIdsOf(out[1]), [productTryonPostbackData("p1")]);
  assertEquals(tryonIdsOf(out[2]), [productTryonPostbackData("p2")]);
  assertEquals(tryonIdsOf(out[3]), [productTryonPostbackData("p3")]);
});

Deno.test("rows beyond LINE's limit are dropped after the fold, chips kept on the last message", () => {
  const out = render([
    text("這幾套都可以"),
    ...Array.from({ length: 6 }, (_, i) => row(card(product(`p${i}`)))),
  ]);

  assertEquals(out.length, 5);
  assertEquals(out[0], { type: "text", text: "這幾套都可以" });
  assertEquals(out.slice(1).map((m) => tryonIdsOf(m)[0]), [0, 1, 2, 3].map((i) => productTryonPostbackData(`p${i}`)));
  assertEquals(chipActions(out.at(-1)!), NARROW_CHIPS);
});

Deno.test("a row longer than one carousel splits rather than truncates", () => {
  const out = render([row(...Array.from({ length: 15 }, (_, i) => card(product(`p${i}`))))]);

  assertEquals(out.length, 2);
  assertEquals(bubbles(out[0]).length, 12);
  assertEquals(bubbles(out[1]).length, 3);
});

Deno.test("products and wardrobe picks in one row share one carousel", () => {
  const out = render([text("配起來像這樣"), row(card(product("p1")), wardrobeCard(wardrobeItem("w1")))]);

  assertEquals(out.length, 2);
  assertEquals(bubbles(out[1]).length, 2);
});

Deno.test("a card whose row is missing is left out rather than drawn empty", () => {
  const out = renderAnswer(
    [
      { type: "text", text: "為你找到" },
      { type: "picks", picks: [{ type: "product", id: "gone" }, { type: "product", id: "p1" }] },
    ],
    { products: { p1: product("p1") }, wardrobe: {} },
    LIFF,
  );

  assertEquals(out.length, 2);
  assertEquals(tryonIdsOf(out[1]), [productTryonPostbackData("p1")]);
});

Deno.test("a row whose picks are all missing draws no carousel", () => {
  const out = renderAnswer(
    [{ type: "text", text: "為你找到" }, { type: "picks", picks: [{ type: "product", id: "gone" }] }],
    { products: {}, wardrobe: {} },
    LIFF,
  );

  assertEquals(out.length, 1);
  assertEquals((out[0] as { type: string }).type, "text");
});

const OUTFIT_CHIPS = [
  { type: "message", label: "換個風格", text: "換個風格看看" },
  { type: "message", label: "便宜一點的", text: "有便宜一點的嗎" },
  { type: "message", label: "用我衣櫃的搭", text: "用我衣櫃裡的衣服幫我搭" },
];

Deno.test("an outfits row is one carousel, a bubble per look", () => {
  const out = render([
    text("兩套都好搭"),
    looks(
      look("週末休閒", card(product("p1")), card(product("p2"))),
      look("溫柔約會", wardrobeCard(wardrobeItem("w1")), card(product("p3"))),
    ),
  ]);

  assertEquals(out.length, 2);
  // deno-lint-ignore no-explicit-any
  const carousel = out[1] as any;
  assertEquals(carousel.altText, "為你搭了 2 套穿搭");
  assertEquals(bubbles(carousel).length, 2);
  assertEquals(bubbles(carousel)[1].hero.contents[1].contents[0].text, "LOOK 02 / 02");
});

Deno.test("a look missing a piece is left out, and a row of none draws no carousel", () => {
  const out = renderAnswer(
    [
      { type: "text", text: "這兩套" },
      {
        type: "outfits",
        outfits: [
          { title: "缺件", pieces: [{ type: "product", id: "p1" }, { type: "product", id: "gone" }] },
          { title: "完整", pieces: [{ type: "product", id: "p1" }, { type: "product", id: "p2" }] },
        ],
      },
    ],
    { products: { p1: product("p1"), p2: product("p2") }, wardrobe: {} },
    LIFF,
  );
  assertEquals(bubbles(out[1]).length, 1);
  assertEquals(bubbles(out[1])[0].hero.contents[1].contents[1].text, "完整");

  const none = renderAnswer(
    [
      { type: "text", text: "這套" },
      { type: "outfits", outfits: [{ title: "缺件", pieces: [{ type: "product", id: "gone" }, { type: "product", id: "p1" }] }] },
    ],
    { products: { p1: product("p1") }, wardrobe: {} },
    LIFF,
  );
  assertEquals(none.length, 1);
});

Deno.test("an answer with outfits offers to steer the next look", () => {
  const out = render([looks(look("週末休閒", card(product("p1")), card(product("p2"))))]);

  assertEquals(chipActions(out.at(-1)!), OUTFIT_CHIPS);
});

Deno.test("an outfits row survives the fold as a single message", () => {
  const out = render([
    text("一"),
    row(card(product("p1"))),
    text("二"),
    row(card(product("p2"))),
    text("三"),
    looks(look("A", card(product("p3")), card(product("p4")))),
  ]);

  assertEquals(out.length, 4);
  assertEquals(out[0], { type: "text", text: "一\n二\n三" });
  // deno-lint-ignore no-explicit-any
  assertEquals((out[3] as any).altText, "為你搭了 1 套穿搭");
});

Deno.test("a duplicated pick renders once", () => {
  const out = renderAnswer(
    [{ type: "picks", picks: [{ type: "product", id: "p1" }, { type: "product", id: "p1" }, { type: "product", id: "p2" }] }],
    { products: { p1: product("p1"), p2: product("p2") }, wardrobe: {} },
    LIFF,
  );
  assertEquals(tryonIdsOf(out[0]), [productTryonPostbackData("p1"), productTryonPostbackData("p2")]);
});

Deno.test("an outfit of one or four pieces renders no bubble", () => {
  const piece = (id: string) => ({ type: "product", id });
  const out = renderAnswer(
    [
      { type: "text", text: "這幾套" },
      {
        type: "outfits",
        outfits: [
          { title: "單件", pieces: [piece("p1")] },
          { title: "重複", pieces: [piece("p1"), piece("p1")] },
          { title: "四件", pieces: ["p1", "p2", "p3", "p4"].map(piece) },
        ],
      },
    ],
    { products: Object.fromEntries(["p1", "p2", "p3", "p4"].map((id) => [id, product(id)])), wardrobe: {} },
    LIFF,
  );
  assertEquals(out.length, 1);
});

Deno.test("an answer of only blank text sends the error message, not an empty text", () => {
  const out = renderAnswer([{ type: "text", text: "  " }, { type: "text" }], NO_ITEMS_FIXTURE, LIFF);
  assertEquals(out, [chatErrorMessage("unknown")]);
});

Deno.test("a blank text beside one picks row sends just the carousel", () => {
  const out = renderAnswer(
    [{ type: "text", text: "  " }, { type: "picks", picks: [{ type: "product", id: "p1" }] }],
    { products: { p1: product("p1") }, wardrobe: {} },
    LIFF,
  );
  assertEquals(out.length, 1);
  assertEquals(bubbles(out[0]).length, 1);
});

Deno.test("looks beyond one carousel's cap spill into the next, numbered globally", () => {
  const ids = Array.from({ length: 14 }, (_, i) => `l${i}`);
  const out = renderAnswer(
    [{
      type: "outfits",
      outfits: ids.map((id) => ({
        title: id,
        pieces: [{ type: "product", id: `${id}a` }, { type: "product", id: `${id}b` }],
      })),
    }],
    {
      products: Object.fromEntries(ids.flatMap((id) => [`${id}a`, `${id}b`]).map((id) => [id, product(id)])),
      wardrobe: {},
    },
    LIFF,
  );
  assertEquals(out.length, 2);
  assertEquals([bubbles(out[0]).length, bubbles(out[1]).length], [12, 2]);
  assertEquals(bubbles(out[1])[0].hero.contents[1].contents[0].text, "LOOK 13 / 14");
});

const NO_ITEMS_FIXTURE: AnswerItems = { products: {}, wardrobe: {} };
