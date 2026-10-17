import { describe, expect, it } from "vitest";
import type { CatalogItem } from "../api/catalog-row";
import type { ResolvedItem } from "../state/chat";
import { collageOrder, outfitPurchase, purchaseCountText } from "./outfit";

const product = (price: number, garmentType = "top", productId = "p"): ResolvedItem => ({
  kind: "product",
  item: {
    productId,
    name: "n",
    price,
    storeName: null,
    imageUrls: [],
    garmentType,
    purchaseLink: null,
    description: null,
  } satisfies CatalogItem,
});
const wardrobe: ResolvedItem = { kind: "wardrobe", id: "w", imagePath: "u/w.png", garmentType: "top", tags: [] };

describe("outfit purchase", () => {
  it("counts and totals only the pieces left to buy", () => {
    expect(outfitPurchase([product(1280), product(599), product(699)])).toEqual({ count: 3, total: 2578 });
    expect(outfitPurchase([wardrobe, product(1380)])).toEqual({ count: 1, total: 1380 });
  });

  it("is null for a wardrobe-only look", () => {
    expect(outfitPurchase([wardrobe, wardrobe])).toBeNull();
  });
});

describe("purchase count text", () => {
  it("counts every piece of a look all for sale, and only what is left of a mixed one", () => {
    expect(purchaseCountText({ count: 3, total: 2578 }, 3)).toBe("共 3 件");
    expect(purchaseCountText({ count: 1, total: 1380 }, 2)).toBe("再買 1 件");
  });
});

describe("collage order", () => {
  it("moves the outerwear to the lead and keeps the rest in order", () => {
    const top = product(1280, "top", "top");
    const pants: ResolvedItem = { kind: "wardrobe", id: "pants", imagePath: "u/p.png", garmentType: "pants", tags: [] };
    const coat = product(2480, "outerwear", "coat");
    expect(collageOrder([top, pants, coat])).toEqual([coat, top, pants]);
  });

  it("leaves a look with no outerwear, or already led by it, as it is", () => {
    const plain = [product(1280, "top"), product(990, "skirt")];
    const led = [product(2480, "outerwear"), product(1980, "one_piece")];
    expect(collageOrder(plain)).toBe(plain);
    expect(collageOrder(led)).toBe(led);
  });
});
