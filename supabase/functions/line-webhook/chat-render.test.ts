import { assertEquals } from "@std/assert";
import { renderAnswer } from "./chat-render.ts";
import type { AnswerItems, ContentBlock } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";
import { CARD_COLOR } from "./card-kit.ts";
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
  | { type: "product"; item: LineProduct }
  | { type: "wardrobe"; item: LineWardrobeItem };

type Part =
  | { type: "text"; text: string }
  | { type: "row"; cards: Card[] };

const text = (t: string): Part => ({ type: "text", text: t });
const card = (p: LineProduct): Card => ({ type: "product", item: p });
const row = (...cards: Card[]): Part => ({ type: "row", cards });

/** Splits fixture parts into what the core hands over: rows of id refs plus the rows they name. */
function render(parts: Part[]): object[] {
  const items: AnswerItems = { products: {}, wardrobe: {} };
  const content: ContentBlock[] = parts.map((part) => {
    if (part.type === "text") return part;
    return {
      type: "recommendation",
      items: part.cards.map((c) => {
        (c.type === "product" ? items.products : items.wardrobe)[c.item.id] = c.item;
        return { type: c.type, id: c.item.id };
      }),
    };
  });
  return renderAnswer(content, items);
}

// deno-lint-ignore no-explicit-any
const tryonIdsOf = (message: any) =>
  // deno-lint-ignore no-explicit-any
  bubbles(message).map((b: any) => b.footer.contents[0].action.data);

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

  assertEquals(first.footer.contents[0].action, {
    type: "postback",
    label: "試穿這件",
    data: productTryonPostbackData("p1"),
    displayText: "試穿「商品 p1」",
  });
  assertEquals(second.footer.contents[0].action.data, productTryonPostbackData("p2"));
});

Deno.test("an over-long product name is clamped in the postback displayText", () => {
  const longName = "衣".repeat(60);
  const out = render([row(card(product("p1", { name: longName })))]);
  const [{ footer }] = bubbles(out[0]);

  const displayText = footer.contents[0].action.displayText as string;
  assertEquals(displayText.length <= 300, true);
  assertEquals(displayText, `試穿「${"衣".repeat(40)}…」`);
});

Deno.test("the try-on button is filled and the purchase button is outlined", () => {
  const out = render([
    row(card(product("p1", { purchaseUrl: "https://shop.example/p1" }))),
  ]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 2);
  assertEquals(footer.contents[0].backgroundColor, "#1A1A1A");
  assertEquals(footer.contents[0].cornerRadius, "8px");
  assertEquals(footer.contents[1].backgroundColor, undefined);
  assertEquals(footer.contents[1].borderWidth, "1px");
  assertEquals(footer.contents[1].action.uri, "https://shop.example/p1");
});

Deno.test("a product with no purchase link still gets its try-on button", () => {
  const out = render([row(card(product("p1")))]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 1);
  assertEquals(footer.contents[0].action.type, "postback");
});

Deno.test("a link LINE would reject is dropped, and takes nothing else with it", () => {
  const out = render([row(card(product("p1", { purchaseUrl: "shop.example/p1" })))]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 1);
  assertEquals(footer.contents[0].action.type, "postback");
});

Deno.test("the card pins its own surface, so no theme can dim the type", () => {
  const [bubble] = bubbles(render([row(card(product("p1")))])[0]);

  assertEquals(bubble.styles.body.backgroundColor, "#FFFFFF");
  assertEquals(bubble.styles.footer.backgroundColor, "#FFFFFF");
});

Deno.test("the body and footer sit on the 8px grid, and do not double up", () => {
  const [bubble] = bubbles(render([row(card(product("p1")))])[0]);

  assertEquals(bubble.body.paddingAll, "16px");
  assertEquals(bubble.footer.paddingAll, "16px");
  // Without this the body's bottom padding and the footer's top padding stack
  // into a 32px gap, which is too much air for a kilo card.
  assertEquals(bubble.footer.paddingTop, "0px");
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

Deno.test("a wardrobe block becomes a card", () => {
  const out = render([text("你衣櫃裡這件可以"), row(wardrobeCard(wardrobeItem("w1")))]);

  assertEquals(out.length, 2);
  // deno-lint-ignore no-explicit-any
  const bubble = bubbles(out[1])[0] as any;
  assertEquals(bubble.hero.url, "https://sig.example/w1.png?token=abc");
  // LINE accepts only `cover` and `fit` here and 400s the whole send otherwise.
  assertEquals(bubble.hero.aspectMode, "fit");
  assertEquals(bubble.hero.backgroundColor, CARD_COLOR.surface);
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
  const [button] = bubble.footer.contents;

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

  assertEquals(bubble.footer.contents[0].action.displayText, "試穿「你的單品」");
});

Deno.test("a product card still offers only its own actions", () => {
  const out = render([row(card(product("p1")))]);
  // deno-lint-ignore no-explicit-any
  const bubble = bubbles(out[0])[0] as any;
  assertEquals(bubble.footer.contents.length, 1);
  assertEquals(bubble.footer.contents[0].action.data, productTryonPostbackData("p1"));
});

Deno.test("a row's items share one carousel", () => {
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

Deno.test("products and wardrobe items in one row share one carousel", () => {
  const out = render([text("配起來像這樣"), row(card(product("p1")), wardrobeCard(wardrobeItem("w1")))]);

  assertEquals(out.length, 2);
  assertEquals(bubbles(out[1]).length, 2);
});

Deno.test("a card whose row is missing is left out rather than drawn empty", () => {
  const out = renderAnswer(
    [
      { type: "text", text: "為你找到" },
      { type: "recommendation", items: [{ type: "product", id: "gone" }, { type: "product", id: "p1" }] },
    ],
    { products: { p1: product("p1") }, wardrobe: {} },
  );

  assertEquals(out.length, 2);
  assertEquals(tryonIdsOf(out[1]), [productTryonPostbackData("p1")]);
});

Deno.test("a row whose items are all missing draws no carousel", () => {
  const out = renderAnswer(
    [{ type: "text", text: "為你找到" }, { type: "recommendation", items: [{ type: "product", id: "gone" }] }],
    { products: {}, wardrobe: {} },
  );

  assertEquals(out.length, 1);
  assertEquals((out[0] as { type: string }).type, "text");
});
