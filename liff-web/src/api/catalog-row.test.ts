import { describe, expect, it } from "vitest";
import { buildCatalogItem, coverImageUrl, resolveColor } from "./catalog-row";

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
  it("keeps every colour in RPC order, dropping blank image paths", () => {
    expect(buildCatalogItem(row, BASE).colors).toEqual([
      {
        id: "c1",
        name: "White",
        imageUrls: ["https://img.test/stores/a/1.jpg", "https://img.test/stores/a/2.jpg"],
      },
      { id: "c2", name: "Navy", imageUrls: ["https://img.test/stores/a/other.jpg"] },
    ]);
  });

  it("skips a colour without usable images", () => {
    const product_colors = [
      { id: "c0", name: "Blank", image_paths: [""], position: 0 },
      row.product_colors[1],
    ];
    expect(buildCatalogItem({ ...row, product_colors }, BASE).colors.map((c) => c.id))
      .toEqual(["c2"]);
  });

  it("keeps a null colour name", () => {
    const product_colors = [{ id: "c", name: null, image_paths: ["a.jpg"], position: 0 }];
    expect(buildCatalogItem({ ...row, product_colors }, BASE).colors[0].name).toBeNull();
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

  it("keeps a product with no usable image, with no colours", () => {
    const emptyCover = [{ id: "c", image_paths: [""], position: 0 }];
    const cases = [undefined, null, [], emptyCover, [{ id: "c", image_paths: [], position: 0 }]];
    for (const product_colors of cases) {
      const item = buildCatalogItem({ ...row, product_colors }, BASE);
      expect(item.colors).toEqual([]);
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

describe("resolveColor and coverImageUrl", () => {
  const item = buildCatalogItem(row, BASE);

  it("returns the requested colour and falls back to the first", () => {
    expect(resolveColor(item, "c2")?.id).toBe("c2");
    expect(resolveColor(item, "gone")?.id).toBe("c1");
    expect(resolveColor(item, null)?.id).toBe("c1");
    expect(resolveColor(item, undefined)?.id).toBe("c1");
  });

  it("is null without colours", () => {
    const bare = buildCatalogItem({ ...row, product_colors: [] }, BASE);
    expect(resolveColor(bare, "c1")).toBeNull();
    expect(coverImageUrl(bare)).toBeNull();
  });

  it("cover is the first image of the first colour", () => {
    expect(coverImageUrl(item)).toBe("https://img.test/stores/a/1.jpg");
  });
});
