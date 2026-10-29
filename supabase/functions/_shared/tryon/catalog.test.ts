import { assertEquals, assertRejects } from "@std/assert";
import { buildProductGarmentDetail, resolveProductGarment } from "./catalog.ts";
import { LIMITS } from "./types.ts";
import { ColorUnavailableError, ValidationError } from "./errors.ts";
import type { DbClient } from "../supabase.ts";

const PRODUCT_ID = "11111111-1111-1111-1111-111111111111";
const COVER_COLOR_ID = "11111111-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const SECOND_COLOR_ID = "22222222-bbbb-4bbb-8bbb-bbbbbbbbbbbb";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

/**
 * `products` is served through `.rpc()`, and `.from()` throws, so a regression
 * to a direct, unfiltered table read fails the suite instead of silently
 * widening what a try-on can reach. The rpc arm re-checks `p_id` and `status`
 * against the stub row, modelling what the SQL function does, so the security
 * test below describes a real outcome and not merely a recorded call.
 */
function fakeAdmin(stubs: Record<string, LookupStub>) {
  const rpcCalls: Array<[string, Record<string, unknown>]> = [];
  const admin = {
    rpc: (name: string, params: Record<string, unknown>) => {
      rpcCalls.push([name, params]);
      const stub = stubs.products;
      const row = stub?.row ?? null;
      const visible = row !== null &&
        row.id === params.p_id &&
        row.status === "active";
      return Promise.resolve({
        data: visible ? row : null,
        error: stub?.error ?? null,
      });
    },
    from: (table: string) => {
      throw new Error(
        `fakeAdmin: unexpected table read of ${table}; the product lookup must go through get_shop_product`,
      );
    },
  } as unknown as DbClient;
  return { admin, rpcCalls };
}

const PRODUCT_ROW = {
  id: PRODUCT_ID,
  status: "active",
  product_colors: [
    {
      id: COVER_COLOR_ID,
      name: "Red",
      image_paths: ["stores/a.jpg"],
      position: 0,
    },
    {
      id: SECOND_COLOR_ID,
      name: "Navy",
      image_paths: ["stores/b.jpg"],
      position: 1,
    },
  ],
  garment_type: "top",
  name: "Shirt",
  material: null,
  fit: null,
  elasticity: null,
  thickness: null,
  description: null,
};

Deno.test("buildProductGarmentDetail joins present fields in fixed order", () => {
  const detail = buildProductGarmentDetail({
    product_colors: [],
    garment_type: "top",
    name: "Linen Shirt",
    material: "100% Linen",
    fit: "regular",
    elasticity: "low",
    thickness: "medium",
    description: " 有內襯 ",
  }, null);
  assertEquals(
    detail,
    "Product: Linen Shirt. Material: 100% Linen. Cut: regular. Elasticity: low. Thickness: medium. Description: 有內襯",
  );
});

Deno.test("buildProductGarmentDetail skips empty and missing fields", () => {
  const detail = buildProductGarmentDetail({
    product_colors: [],
    garment_type: "top",
    name: "  Tee  ",
    material: "",
    fit: null,
    elasticity: undefined,
    thickness: "high",
    description: null,
  }, null);
  assertEquals(detail, "Product: Tee. Thickness: high");
});

Deno.test("buildProductGarmentDetail returns undefined when all empty", () => {
  const detail = buildProductGarmentDetail({
    product_colors: [],
    garment_type: "top",
    name: null,
    material: null,
    fit: null,
    elasticity: null,
    thickness: null,
    description: null,
  }, null);
  assertEquals(detail, undefined);
});

Deno.test("buildProductGarmentDetail caps overlong detail at the limit", () => {
  const detail = buildProductGarmentDetail({
    product_colors: [],
    garment_type: "top",
    name: "x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 200),
    material: null,
    fit: null,
    elasticity: null,
    thickness: null,
    description: null,
  }, null);
  assertEquals(detail?.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
});

Deno.test("buildProductGarmentDetail lets the cap cut the description, not an attribute", () => {
  const detail = buildProductGarmentDetail({
    product_colors: [],
    garment_type: "top",
    name: "Tee",
    material: null,
    fit: null,
    elasticity: null,
    thickness: "high",
    description: "x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH),
  }, null);
  assertEquals(detail?.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
  assertEquals(
    detail?.startsWith("Product: Tee. Thickness: high. Description: x"),
    true,
  );
});

Deno.test("resolveProductGarment looks the product up through get_shop_product", async () => {
  const { admin, rpcCalls } = fakeAdmin({ products: { row: PRODUCT_ROW } });
  await resolveProductGarment(admin, { productId: PRODUCT_ID });

  assertEquals(rpcCalls, [["get_shop_product", { p_id: PRODUCT_ID }]]);
});

Deno.test("SECURITY: an unlisted product does not resolve", async () => {
  // An archived product keeps its row; what keeps it out of a try-on is
  // `get_shop_product`'s `status = 'active'`, which the fake models.
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, status: "archived" } },
  });

  await assertRejects(
    () => resolveProductGarment(admin, { productId: PRODUCT_ID }),
    ValidationError,
    "no product for productId",
  );
});

Deno.test("resolveProductGarment sends only the product's first image", async () => {
  const { admin } = fakeAdmin({
    products: {
      row: {
        ...PRODUCT_ROW,
        product_colors: [{
          id: COVER_COLOR_ID,
          name: null,
          position: 0,
          image_paths: [
            "stores/main.jpg",
            "stores/label.jpg",
            "stores/hem.jpg",
          ],
        }],
      },
    },
  });

  const garment = await resolveProductGarment(admin, { productId: PRODUCT_ID });

  assertEquals(garment.images, [{ publicImageKey: "stores/main.jpg" }]);
});

Deno.test("resolveProductGarment carries the product's garment type", async () => {
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, garment_type: "skirt" } },
  });

  const garment = await resolveProductGarment(admin, { productId: PRODUCT_ID });

  assertEquals(garment.garmentType, "skirt");
});

Deno.test("resolveProductGarment ignores a garment type outside the vocabulary", async () => {
  // The column is an enum, but the row arrives as untyped jsonb from the RPC.
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, garment_type: "dress" } },
  });

  const garment = await resolveProductGarment(admin, { productId: PRODUCT_ID });

  assertEquals("garmentType" in garment, false);
});

Deno.test("resolveProductGarment sends the cover colour's image and reports it as worn", async () => {
  const { admin } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  const garment = await resolveProductGarment(admin, { productId: PRODUCT_ID });

  assertEquals(garment.images, [{ publicImageKey: "stores/a.jpg" }]);
  assertEquals(garment.worn, {
    productId: PRODUCT_ID,
    colorId: COVER_COLOR_ID,
  });
});

Deno.test("resolveProductGarment rejects a product with no usable colour image", async () => {
  const { admin } = fakeAdmin({
    products: { row: { ...PRODUCT_ROW, product_colors: [] } },
  });

  await assertRejects(
    () => resolveProductGarment(admin, { productId: PRODUCT_ID }),
    ValidationError,
    "no usable garment image",
  );
});

Deno.test("resolveProductGarment wears the requested colour", async () => {
  const { admin } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  const garment = await resolveProductGarment(admin, {
    productId: PRODUCT_ID,
    colorId: SECOND_COLOR_ID,
  });

  assertEquals(garment.images, [{ publicImageKey: "stores/b.jpg" }]);
  assertEquals(garment.worn, {
    productId: PRODUCT_ID,
    colorId: SECOND_COLOR_ID,
  });
  assertEquals(garment.detail?.includes("Color: Navy"), true);
});

Deno.test("resolveProductGarment reports a colour the product no longer has as unavailable", async () => {
  const { admin } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  await assertRejects(
    () =>
      resolveProductGarment(admin, {
        productId: PRODUCT_ID,
        colorId: "33333333-cccc-4ccc-8ccc-cccccccccccc",
      }),
    ColorUnavailableError,
    "no colour 33333333-cccc-4ccc-8ccc-cccccccccccc for productId",
  );
});

Deno.test("resolveProductGarment a non-uuid colorId is a validation error", async () => {
  const { admin, rpcCalls } = fakeAdmin({ products: { row: PRODUCT_ROW } });

  await assertRejects(
    () =>
      resolveProductGarment(admin, {
        productId: PRODUCT_ID,
        colorId: "not-a-uuid",
      }),
    ValidationError,
    "invalid colorId",
  );
  assertEquals(rpcCalls, []);
});

Deno.test("buildProductGarmentDetail the garment detail names the colour", () => {
  const row = {
    product_colors: [],
    garment_type: "top",
    name: "Tee",
    material: "Cotton",
    fit: null,
    elasticity: null,
    thickness: null,
    description: null,
  };
  assertEquals(
    buildProductGarmentDetail(row, "霧灰"),
    "Product: Tee. Color: 霧灰. Material: Cotton",
  );
  assertEquals(
    buildProductGarmentDetail(row, null)?.includes("Color:"),
    false,
  );
});
