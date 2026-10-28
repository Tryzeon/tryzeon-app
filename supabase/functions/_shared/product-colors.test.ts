import { assertEquals } from "@std/assert";
import {
  coverColor,
  coverImagePath,
  orderProductColors,
} from "./product-colors.ts";

Deno.test("coverColor takes the first colour as delivered", () => {
  const row = {
    product_colors: [
      { id: "b", name: "黑", image_paths: ["k2"], position: 1 },
      { id: "a", name: "白", image_paths: ["k1"], position: 0 },
    ],
  };
  assertEquals(coverColor(row)?.id, "b");
  assertEquals(coverImagePath(row), "k2");
});

Deno.test("coverColor is undefined when the first colour is malformed", () => {
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
    assertEquals(coverColor({ product_colors: [first] }), undefined);
  }
});

Deno.test("coverColor is undefined for missing, non-array or empty colours", () => {
  assertEquals(coverColor({}), undefined);
  assertEquals(coverColor({ product_colors: null }), undefined);
  assertEquals(coverColor({ product_colors: [] }), undefined);
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
