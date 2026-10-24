import { assertEquals } from "@std/assert";
import { isGarmentType } from "./types.ts";
import { GARMENT_TYPE_VALUES } from "../vocabularies.ts";

Deno.test("isGarmentType accepts every vocabulary value", () => {
  for (const value of GARMENT_TYPE_VALUES) {
    assertEquals(isGarmentType(value), true);
  }
});

Deno.test("isGarmentType rejects anything outside the vocabulary", () => {
  assertEquals(isGarmentType("dress"), false);
  assertEquals(isGarmentType("TOP"), false);
  assertEquals(isGarmentType(""), false);
  assertEquals(isGarmentType(null), false);
  assertEquals(isGarmentType(undefined), false);
  assertEquals(isGarmentType(7), false);
  assertEquals(isGarmentType(["top"]), false);
});
