-- Store-authored, shopper-facing free text shown on the product page (app and
-- LIFF web). Read through `get_shop_product` here; `list_shop_products` picks
-- it up in 20260910010000.
--
-- The length cap is enforced here and mirrored by
-- `AppValidators.validateProductDescription`; keep the two numbers in step.

ALTER TABLE "public"."products"
  ADD COLUMN "description" "text",
  ADD CONSTRAINT "products_description_length"
    CHECK ("description" IS NULL OR char_length("description") <= 500);

CREATE OR REPLACE FUNCTION "public"."get_shop_product"("p_id" "uuid")
RETURNS "jsonb"
LANGUAGE "sql" STABLE
AS $$
  SELECT to_jsonb(t) FROM (
    SELECT
      p.id,
      p.name,
      p.price,
      p.image_paths,
      p.purchase_link,
      p.description,
      p.material,
      p.elasticity,
      p.fit,
      p.thickness,
      jsonb_build_object('name', s.name) AS store_profiles
    FROM products p
    JOIN store_profiles s ON s.id = p.store_id
    WHERE p.id = p_id
      AND p.status = 'active'
  ) t;
$$;
