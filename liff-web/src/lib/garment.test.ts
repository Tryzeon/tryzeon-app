import { describe, expect, it } from "vitest";
import { garmentTypeLabel, wardrobeCardName } from "./garment";

describe("garmentTypeLabel", () => {
  it("names every wardrobe garment type", () => {
    expect(["top", "pants", "skirt", "one_piece", "outerwear", "others"].map(garmentTypeLabel))
      .toEqual(["上衣", "褲子", "裙子", "連身", "外套", "其他"]);
  });

  it("falls back to 單品 for a type it does not know", () => {
    expect(garmentTypeLabel(null)).toBe("單品");
    expect(garmentTypeLabel("hat")).toBe("單品");
  });
});

describe("wardrobeCardName", () => {
  it("joins the garment label with the first two tags", () => {
    expect(wardrobeCardName("top", ["白色", "棉質", "休閒"])).toBe("上衣 · 白色 · 棉質");
  });

  it("is just the label when there are no tags", () => {
    expect(wardrobeCardName("top", [])).toBe("上衣");
  });

  it("names an unknown type 單品", () => {
    expect(wardrobeCardName("hat", ["白色"])).toBe("單品 · 白色");
  });
});
