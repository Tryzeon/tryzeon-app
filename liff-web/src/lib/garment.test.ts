import { describe, expect, it } from "vitest";
import type { CatalogItem } from "../api/catalog-row";
import { garmentTypeLabel, productCaption, productGarment, wardrobeCardName } from "./garment";

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

const color = (id: string, name: string | null = id) => ({ id, name, imageUrls: [`https://x/${id}.jpg`] });

const item = (colors = [color("navy"), color("cream")]): CatalogItem => ({
  productId: "p1",
  name: "Knit",
  price: 599,
  storeName: null,
  colors,
  garmentType: "top",
  purchaseLink: null,
  description: null,
});

describe("productGarment", () => {
  it("wears the colour that was shown", () => {
    const knit = item();
    expect(productGarment(knit, knit.colors[1])).toEqual({ productId: "p1", colorId: "cream" });
    expect(productGarment(knit, knit.colors[0])).toEqual({ productId: "p1", colorId: "navy" });
  });

  it("wears the cover when no colour is given", () => {
    expect(productGarment(item())).toEqual({ productId: "p1", colorId: "navy" });
  });

  it("names no colour for a product without one", () => {
    expect(productGarment(item([]))).toEqual({ productId: "p1" });
  });
});

describe("productCaption", () => {
  it("names the colour when the product offers a choice", () => {
    const knit = item();
    expect(productCaption(knit, knit.colors[1])).toBe("Knit · cream");
  });

  it("is just the name for a single colour or an unnamed one", () => {
    expect(productCaption(item([color("navy")]), color("navy"))).toBe("Knit");
    expect(productCaption(item([color("a", null), color("b")]), color("a", null))).toBe("Knit");
  });
});
