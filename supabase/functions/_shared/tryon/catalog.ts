import { isUuid } from "../text.ts";
import { ValidationError } from "./errors.ts";
import { isGarmentType, LIMITS } from "./types.ts";
import type { ProductRef, ResolvedGarment } from "./types.ts";
import { productColor } from "../product-colors.ts";
import { asJsonObject, type DbClient } from "../supabase.ts";

export interface ProductGarmentRow {
  product_colors: unknown;
  garment_type: unknown;
  name: unknown;
  material: unknown;
  fit: unknown;
  elasticity: unknown;
  thickness: unknown;
  description: unknown;
}

function trimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * `products.fit` is emitted as `Cut:`, not `Fit:`: it is a label derived from
 * the product photo (see `analyze-product-image`) describing the design
 * silhouette on a generic body, saying nothing about this wearer.
 */
export function buildProductGarmentDetail(
  row: ProductGarmentRow,
  colorName: string | null,
): string | undefined {
  const parts: string[] = [];
  const name = trimmedString(row.name);
  if (name) parts.push(`Product: ${name}`);
  const color = trimmedString(colorName);
  if (color) parts.push(`Color: ${color}`);
  const material = trimmedString(row.material);
  if (material) parts.push(`Material: ${material}`);
  const cut = trimmedString(row.fit);
  if (cut) parts.push(`Cut: ${cut}`);
  const elasticity = trimmedString(row.elasticity);
  if (elasticity) parts.push(`Elasticity: ${elasticity}`);
  const thickness = trimmedString(row.thickness);
  if (thickness) parts.push(`Thickness: ${thickness}`);
  const description = trimmedString(row.description);
  if (description) parts.push(`Description: ${description}`);
  if (parts.length === 0) return undefined;
  return parts.join(". ").slice(0, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
}

export async function resolveProductGarment(
  client: DbClient,
  ref: ProductRef,
): Promise<ResolvedGarment> {
  const { productId, colorId } = ref;
  // Reject non-UUID ids up front so garbage yields a clean validation error
  // instead of a Postgres "invalid input syntax for type uuid".
  if (!isUuid(productId)) {
    throw new ValidationError(`invalid productId: ${productId}`);
  }
  if (colorId !== undefined && !isUuid(colorId)) {
    throw new ValidationError(`invalid colorId: ${colorId}`);
  }
  const { data, error } = await client.rpc("get_shop_product", {
    p_id: productId,
  });

  if (error) {
    throw new Error(`product lookup failed: ${error.message}`);
  }
  const row = asJsonObject<ProductGarmentRow>(data);
  if (!row) {
    throw new ValidationError(`no product for productId: ${productId}`);
  }

  const color = productColor(row, colorId);
  if (!color) {
    throw new ValidationError(
      colorId === undefined
        ? `no usable garment image for productId: ${productId}`
        : `no colour ${colorId} for productId: ${productId}`,
    );
  }

  // The colour's first shot only: a store's later images are detail macros carrying no
  // garment silhouette, and passing them off as extra angles dilutes the person
  // photo instead of describing the garment.
  const images = [{ publicImageKey: color.image_paths[0] }];

  const detail = buildProductGarmentDetail(row, color.name);

  const garment: ResolvedGarment = {
    images,
    worn: { productId, colorId: color.id },
  };
  if (isGarmentType(row.garment_type)) garment.garmentType = row.garment_type;
  if (detail !== undefined) garment.detail = detail;
  return garment;
}
