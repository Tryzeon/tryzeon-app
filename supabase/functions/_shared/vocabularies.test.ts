import { assertEquals } from "@std/assert";
import {
  CHANNEL_VALUES,
  ELASTICITY_VALUES,
  FIT_VALUES,
  GARMENT_TYPE_VALUES,
  GENDER_VALUES,
  SEASON_VALUES,
  STYLE_GUIDE,
  STYLE_VALUES,
  THICKNESS_VALUES,
} from "./vocabularies.ts";

Deno.test("vocabularies match the schema enums", () => {
  assertEquals([...SEASON_VALUES], ["spring", "summer", "autumn", "winter"]);
  assertEquals([...THICKNESS_VALUES], ["low", "medium", "high"]);
  assertEquals([...ELASTICITY_VALUES], ["none", "low", "medium", "high"]);
  assertEquals([...FIT_VALUES], ["slim", "regular", "loose", "oversize"]);
  assertEquals([...CHANNEL_VALUES], ["physical", "online"]);
  assertEquals([...GENDER_VALUES], ["male", "female", "unisex"]);
});

Deno.test("garment types name one_piece, not dress", () => {
  assertEquals([...GARMENT_TYPE_VALUES], [
    "top",
    "outerwear",
    "pants",
    "skirt",
    "one_piece",
    "others",
  ]);
});

Deno.test("no vocabulary is empty", () => {
  for (
    const v of [
      SEASON_VALUES,
      THICKNESS_VALUES,
      ELASTICITY_VALUES,
      FIT_VALUES,
      CHANNEL_VALUES,
      GENDER_VALUES,
      GARMENT_TYPE_VALUES,
    ]
  ) {
    assertEquals(v.length > 0, true);
  }
});

Deno.test("styles are the thirteen shopper-facing styles in display order", () => {
  assertEquals([...STYLE_VALUES], [
    "basic",
    "casual",
    "business",
    "elegant",
    "sweet",
    "streetwear",
    "sporty",
    "vintage",
    "preppy",
    "edgy",
    "natural",
    "party",
    "homewear",
  ]);
});

Deno.test("every style carries a Chinese name and a description", () => {
  assertEquals(Object.keys(STYLE_GUIDE).sort(), [...STYLE_VALUES].sort());
  for (const value of STYLE_VALUES) {
    const { name, description } = STYLE_GUIDE[value];
    assertEquals(name.length > 0, true, `${value} has no name`);
    assertEquals(description.length > 0, true, `${value} has no description`);
  }
  assertEquals(STYLE_GUIDE.basic.name, "簡約基本");
  assertEquals(STYLE_GUIDE.homewear.name, "居家舒適");
});
