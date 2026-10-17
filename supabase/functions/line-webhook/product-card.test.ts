import { assertEquals, assertRejects } from "@std/assert";
import {
  clampProductName,
  fetchProductInfo,
  fetchProductRows,
  priceText,
  type LineProduct,
  productDetailUrl,
  productInfoContents,
  productItemBubble,
  purchaseAction,
  toLineProduct,
} from "./product-card.ts";
import { CARD_COLOR, pickBubble, sourceLine } from "./card-kit.ts";
import { productTryonPostbackData } from "./postback.ts";

const BASE = "https://img.example";

const row = (over: Record<string, unknown> = {}) => ({
  id: "p1",
  name: "白襯衫",
  price: 1200,
  image_paths: ["stores/s1/p1.jpg"],
  garment_type: "top",
  purchase_link: null,
  store_profiles: { name: "某店" },
  ...over,
});

const product = (over: Partial<LineProduct> = {}): LineProduct => ({
  id: "p1",
  name: "白襯衫",
  price: 1200,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  garmentType: "top",
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

/**
 * `.from()` throws: the unlisted-product filter lives in `get_shop_product` now,
 * so a direct `products` read is a regression, not an alternative.
 */
// deno-lint-ignore no-explicit-any
function fakeAdmin(result: { data: any; error: any }) {
  const queried: string[] = [];
  const calls: Array<[string, Record<string, unknown>]> = [];
  const client = {
    rpc(name: string, params: Record<string, unknown>) {
      calls.push([name, params]);
      queried.push(params.p_id as string);
      return Promise.resolve(result);
    },
    from() {
      throw new Error(
        "fakeAdmin: fetchProductInfo must go through get_shop_product",
      );
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, queried, calls };
}

// deno-lint-ignore no-explicit-any
function fakeBatchAdmin(result: { data: any; error: any }) {
  const queried: string[][] = [];
  const eqCalls: Array<[string, string]> = [];
  const runIn = (_column: string, ids: string[]) => {
    queried.push(ids);
    return Promise.resolve(result);
  };
  const client = {
    from() {
      return {
        select() {
          return {
            in: runIn,
            eq(column: string, value: string) {
              eqCalls.push([column, value]);
              return { in: runIn };
            },
          };
        },
      };
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, queried, eqCalls };
}

Deno.test("toLineProduct joins the image key onto the public base", () => {
  assertEquals(toLineProduct(row(), BASE), {
    id: "p1",
    name: "白襯衫",
    price: 1200,
    imageUrl: "https://img.example/stores/s1/p1.jpg",
    garmentType: "top",
    storeName: "某店",
    purchaseUrl: null,
  });
});

Deno.test("toLineProduct drops a product with no image", () => {
  assertEquals(toLineProduct(row({ image_paths: [] }), BASE), null);
  assertEquals(toLineProduct(row({ image_paths: null }), BASE), null);
});

Deno.test("toLineProduct tolerates a product with no store", () => {
  assertEquals(toLineProduct(row({ store_profiles: null }), BASE)?.storeName, null);
});

Deno.test("toLineProduct does not double up a trailing slash on the base", () => {
  assertEquals(
    toLineProduct(row(), `${BASE}/`)?.imageUrl,
    "https://img.example/stores/s1/p1.jpg",
  );
});

Deno.test("fetchProductInfo reads the asked-for id", async () => {
  const { admin, queried } = fakeAdmin({ data: row(), error: null });
  const found = await fetchProductInfo(admin, "p1");

  assertEquals(queried, ["p1"]);
  assertEquals(found?.name, "白襯衫");
});

Deno.test("fetchProductInfo is null for a product that is gone", async () => {
  const { admin } = fakeAdmin({ data: null, error: null });
  assertEquals(await fetchProductInfo(admin, "p1"), null);
});

Deno.test("fetchProductInfo is null for a product with no image", async () => {
  const { admin } = fakeAdmin({ data: row({ image_paths: [] }), error: null });
  assertEquals(await fetchProductInfo(admin, "p1"), null);
});

Deno.test("fetchProductInfo throws when the lookup itself failed", async () => {
  const { admin } = fakeAdmin({ data: null, error: { message: "boom" } });
  await assertRejects(() => fetchProductInfo(admin, "p1"), Error, "boom");
});

Deno.test("fetchProductRows keys the rows by product id", async () => {
  const { admin, queried } = fakeBatchAdmin({
    data: [row(), row({ id: "p2", name: "黑褲" })],
    error: null,
  });
  const rows = await fetchProductRows(admin, ["p1", "p2"], BASE);

  assertEquals(queried, [["p1", "p2"]]);
  assertEquals([...rows.keys()], ["p1", "p2"]);
  assertEquals(rows.get("p2")?.name, "黑褲");
});

Deno.test("fetchProductRows leaves out a product with no image", async () => {
  const { admin } = fakeBatchAdmin({
    data: [row(), row({ id: "p2", image_paths: [] })],
    error: null,
  });
  const rows = await fetchProductRows(admin, ["p1", "p2"], BASE);

  // Absent, not present-and-null: the assembler drops it by the missing-row rule.
  assertEquals([...rows.keys()], ["p1"]);
});

Deno.test("fetchProductRows queries nothing for an empty id list", async () => {
  const { admin, queried } = fakeBatchAdmin({ data: null, error: null });
  const rows = await fetchProductRows(admin, [], BASE);

  assertEquals(queried, []);
  assertEquals(rows.size, 0);
});

Deno.test("fetchProductRows throws when the lookup itself failed", async () => {
  const { admin } = fakeBatchAdmin({ data: null, error: { message: "boom" } });
  await assertRejects(() => fetchProductRows(admin, ["p1"], BASE));
});

Deno.test("fetchProductRows reads only listed products, as get_shop_product does", async () => {
  const { admin, eqCalls } = fakeBatchAdmin({ data: [row()], error: null });
  await fetchProductRows(admin, ["p1"], BASE);

  // A card can be tapped days after it was sent; a try-on the core would refuse
  // for an unlisted product has to be refused before quota is charged.
  assertEquals(eqCalls, [["status", "active"]]);
});

Deno.test("fetchProductInfo will not act on an unlisted product", async () => {
  const { admin, calls } = fakeAdmin({ data: row(), error: null });
  await fetchProductInfo(admin, "p1");

  assertEquals(calls, [["get_shop_product", { p_id: "p1" }]]);
});

Deno.test("purchaseAction is offered only for an absolute http link", () => {
  assertEquals(purchaseAction(product({ purchaseUrl: "https://shop.example/p1" })), {
    type: "uri",
    label: "前往購買",
    uri: "https://shop.example/p1",
  });
  assertEquals(purchaseAction(product({ purchaseUrl: "shop.example/p1" })), null);
  assertEquals(purchaseAction(product({ purchaseUrl: "" })), null);
  assertEquals(purchaseAction(product()), null);
});

Deno.test("purchaseAction rejects strings a bare startsWith(\"http\") check let through", () => {
  assertEquals(purchaseAction(product({ purchaseUrl: "http" })), null);
  assertEquals(purchaseAction(product({ purchaseUrl: "httpfoo://x" })), null);
  // `new URL` normalizes a single-slash scheme to a valid "https://one-slash/",
  // so a bare protocol check on the parsed result would wave it through.
  assertEquals(purchaseAction(product({ purchaseUrl: "https:/one-slash" })), null);
});

Deno.test("priceText prefixes NT$, groups thousands and drops cents", () => {
  assertEquals(priceText(1200), "NT$1,200");
  assertEquals(priceText(1199.6), "NT$1,200");
  assertEquals(priceText(0), "NT$0");
});

Deno.test("the info block is store in ink, then the name muted, then the price", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: "Studio Muji" })) as any[];

  assertEquals(contents.length, 3);
  assertEquals(contents[0], sourceLine("STUDIO MUJI"));
  assertEquals(contents[1].text, "白襯衫");
  assertEquals(contents[1].color, CARD_COLOR.mutedText);
  assertEquals(contents[1].weight, undefined);
  assertEquals(contents[2].text, "NT$1,200");
});

Deno.test("a product with no store shows two lines, not an empty third", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: null })) as any[];
  assertEquals(contents.length, 2);
});

Deno.test("the price is one bold line in the shared NT$ format", () => {
  // deno-lint-ignore no-explicit-any
  const price = (productInfoContents(product()) as any[]).at(-1);

  assertEquals(price.text, "NT$1,200");
  assertEquals(price.weight, "bold");
  assertEquals(price.color, CARD_COLOR.primary);
});

Deno.test("a Chinese store name is unchanged by uppercasing", () => {
  // deno-lint-ignore no-explicit-any
  const contents = productInfoContents(product({ storeName: "某店" })) as any[];
  assertEquals(contents[0].text, "某店");
});

Deno.test("clampProductName leaves a short name untouched", () => {
  assertEquals(clampProductName("白襯衫"), "白襯衫");
  assertEquals(clampProductName("a".repeat(40)), "a".repeat(40));
});

Deno.test("clampProductName truncates a long name with an ellipsis", () => {
  const long = "a".repeat(41);
  assertEquals(clampProductName(long), `${"a".repeat(40)}…`);
});

Deno.test("productDetailUrl points at the LIFF product page", () => {
  assertEquals(productDetailUrl("https://liff.line.me/123-abc", "p1"), "https://liff.line.me/123-abc/product/p1");
});

const detail = { type: "uri", label: "商品詳情", uri: "https://liff.example/product/p1" };

Deno.test("an item bubble is the shared pick bubble, opening its LIFF page", () => {
  assertEquals(
    productItemBubble(product(), "顯瘦直筒", "https://liff.example"),
    pickBubble({
      imageUrl: "https://img.example/stores/s1/p1.jpg",
      highlight: "顯瘦直筒",
      source: "某店",
      name: "白襯衫",
      value: { text: "NT$1,200", muted: false },
      tryonAction: {
        type: "postback",
        label: "試穿",
        data: productTryonPostbackData("p1"),
        displayText: "試穿「白襯衫」",
      },
      detailAction: detail,
    }),
  );
});

Deno.test("an item bubble uppercases a Latin store name", () => {
  // deno-lint-ignore no-explicit-any
  const overlay = (productItemBubble(product({ storeName: "uniqlo" }), undefined, "https://liff.example") as any)
    .hero.contents[1];
  assertEquals(overlay.contents[0].text, "UNIQLO");
});

Deno.test("an item bubble for a product with no store has no source line", () => {
  // deno-lint-ignore no-explicit-any
  const overlay = (productItemBubble(product({ storeName: null }), undefined, "https://liff.example") as any)
    .hero.contents[1];
  assertEquals(overlay.contents.length, 2);
  assertEquals(overlay.contents[0].text, "白襯衫");
});

Deno.test("an item bubble clamps a long name in the try-on displayText", () => {
  const name = "很長的商品名稱".repeat(60);
  // deno-lint-ignore no-explicit-any
  const overlay = (productItemBubble(product({ name }), undefined, "https://liff.example") as any).hero.contents[1];
  const pill = overlay.contents.at(-1).contents[1];
  assertEquals(pill.action.displayText, `試穿「${clampProductName(name)}」`);
});
