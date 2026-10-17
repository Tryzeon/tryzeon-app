import { describe, expect, it } from "vitest";
import { garmentTypeLabel } from "./garment";

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
