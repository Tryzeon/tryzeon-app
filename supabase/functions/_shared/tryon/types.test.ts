import { assertEquals } from "@std/assert";
import { garmentCategoryOf, isGarmentType } from "./types.ts";
import { GARMENT_TYPE_VALUES } from "../vocabularies.ts";

Deno.test("garmentCategoryOf maps every garment type the database can hold", () => {
  assertEquals(garmentCategoryOf("top"), "top");
  assertEquals(garmentCategoryOf("outerwear"), "outerwear");
  assertEquals(garmentCategoryOf("pants"), "bottom");
  assertEquals(garmentCategoryOf("skirt"), "bottom");
  assertEquals(garmentCategoryOf("one_piece"), "full_body");
  assertEquals(garmentCategoryOf("others"), undefined);
});

Deno.test("garmentCategoryOf leaves no enum value unhandled", () => {
  // `others` is the one value that deliberately names no replacement scope;
  // anything else falling through would silently reach the prompt uncategorized.
  const unmapped = GARMENT_TYPE_VALUES.filter((t) =>
    garmentCategoryOf(t) === undefined
  );
  assertEquals(unmapped, ["others"]);
});

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
