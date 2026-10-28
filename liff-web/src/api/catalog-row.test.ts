import { describe, expect, it } from "vitest";
import { buildCatalogItem } from "./catalog-row";

const BASE = "https://img.test";

const row = {
  id: "11111111-1111-1111-1111-111111111111",
  name: "Linen Shirt",
  price: 1280,
  product_colors: [
    {
      id: "c1",
      name: "White",
      image_paths: ["stores/a/1.jpg", "", "stores/a/2.jpg"],
      position: 0,
    },
    {
      id: "c2",
      name: "Navy",
      image_paths: ["stores/a/other.jpg"],
      position: 1,
    },
  ],
  garment_type: "top",
  purchase_link: "https://shop.test/p/1",
  store_profiles: { id: "s1", name: "Island Select" },
};

describe("buildCatalogItem", () => {
  it("projects every image of the first colour, as the RPC orders them", () => {
    expect(buildCatalogItem(row, BASE).imageUrls).toEqual([
      "https://img.test/stores/a/1.jpg",
      "https://img.test/stores/a/2.jpg",
    ]);
  });

  it("carries purchase link, store name and price", () => {
    const item = buildCatalogItem(row, BASE);
    expect(item.productId).toBe("11111111-1111-1111-1111-111111111111");
    expect(item.name).toBe("Linen Shirt");
    expect(item.price).toBe(1280);
    expect(item.storeName).toBe("Island Select");
    expect(item.purchaseLink).toBe("https://shop.test/p/1");
  });

  it("carries the garment type, null when the row has none", () => {
    expect(buildCatalogItem(row, BASE).garmentType).toBe("top");
    expect(buildCatalogItem({ ...row, garment_type: undefined }, BASE).garmentType).toBeNull();
  });

  it("normalizes a blank purchase link to null", () => {
    expect(buildCatalogItem({ ...row, purchase_link: "" }, BASE).purchaseLink)
      .toBeNull();
    expect(buildCatalogItem({ ...row, purchase_link: null }, BASE).purchaseLink)
      .toBeNull();
  });

  it("keeps a product with no usable image, with no urls", () => {
    const emptyCover = [{ id: "c", image_paths: [""], position: 0 }];
    const cases = [undefined, null, [], emptyCover, [{ id: "c", image_paths: [], position: 0 }]];
    for (const product_colors of cases) {
      const item = buildCatalogItem({ ...row, product_colors }, BASE);
      expect(item.imageUrls).toEqual([]);
      expect(item.name).toBe("Linen Shirt");
    }
  });

  it("tolerates a missing store", () => {
    expect(buildCatalogItem({ ...row, store_profiles: null }, BASE).storeName)
      .toBeNull();
  });
});

describe("buildCatalogItem description", () => {
  it("carries the description", () => {
    expect(buildCatalogItem({ ...row, description: "亞麻襯衫" }, BASE).description)
      .toBe("亞麻襯衫");
  });

  it("normalizes a missing or blank description to null", () => {
    expect(buildCatalogItem(row, BASE).description).toBeNull();
    expect(buildCatalogItem({ ...row, description: "" }, BASE).description)
      .toBeNull();
    expect(buildCatalogItem({ ...row, description: null }, BASE).description)
      .toBeNull();
  });
});
