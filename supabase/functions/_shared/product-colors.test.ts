import { assertEquals } from "@std/assert";
import {
  coverImagePath,
  orderProductColors,
  productColor,
  productColors,
} from "./product-colors.ts";

Deno.test("the cover is the first colour as delivered", () => {
  const row = {
    product_colors: [
      { id: "b", name: "黑", image_paths: ["k2"], position: 1 },
      { id: "a", name: "白", image_paths: ["k1"], position: 0 },
    ],
  };
  assertEquals(productColor(row, undefined)?.id, "b");
  assertEquals(coverImagePath(row), "k2");
});

Deno.test("no cover when the first colour is malformed", () => {
  for (
    const first of [
      null,
      "x",
      { id: 1, image_paths: ["k"] },
      { id: "a", image_paths: null },
      { id: "a", image_paths: [] },
      { id: "a", image_paths: [""] },
    ]
  ) {
    assertEquals(coverImagePath({ product_colors: [first] }), undefined);
  }
});

Deno.test("no cover for missing, non-array or empty colours", () => {
  assertEquals(coverImagePath({}), undefined);
  assertEquals(coverImagePath({ product_colors: null }), undefined);
  assertEquals(coverImagePath({ product_colors: [] }), undefined);
});

Deno.test("orderProductColors orders the embed by position, created_at, id", () => {
  const calls: Array<[string, string]> = [];
  const query = {
    order(column: string, options: { referencedTable: string }) {
      calls.push([column, options.referencedTable]);
      return this;
    },
  };
  assertEquals(orderProductColors(query), query);
  assertEquals(calls, [
    ["position", "product_colors"],
    ["created_at", "product_colors"],
    ["id", "product_colors"],
  ]);
});

const TWO_COLORS = {
  product_colors: [
    { id: "a", name: "白", image_paths: ["k1"], position: 0 },
    { id: "b", name: "黑", image_paths: ["k2", "k3"], position: 1 },
  ],
};

Deno.test("productColor picks the requested colour", () => {
  assertEquals(productColor(TWO_COLORS, "b"), {
    id: "b",
    name: "黑",
    image_paths: ["k2", "k3"],
  });
});

Deno.test("productColor falls back to the cover only when no id is given", () => {
  assertEquals(productColor(TWO_COLORS, undefined)?.id, "a");
});

Deno.test("productColor rejects an id the product does not have", () => {
  assertEquals(productColor(TWO_COLORS, "zzz"), undefined);
});

Deno.test("productColor rejects a requested colour with no usable image", () => {
  const row = {
    product_colors: [
      { id: "a", name: "白", image_paths: ["k1"], position: 0 },
      { id: "b", name: "黑", image_paths: [""], position: 1 },
    ],
  };
  assertEquals(productColor(row, "b"), undefined);
});

Deno.test("productColors keeps every usable colour in the order delivered", () => {
  const row = {
    product_colors: [
      { id: "a", name: "白", image_paths: ["k1"] },
      { id: "x", name: "無圖", image_paths: [] },
      "junk",
      { id: "b", name: null, image_paths: ["k2", "k3"] },
    ],
  };
  assertEquals(productColors(row).map((c) => c.id), ["a", "b"]);
  assertEquals(productColors({ product_colors: null }), []);
});
