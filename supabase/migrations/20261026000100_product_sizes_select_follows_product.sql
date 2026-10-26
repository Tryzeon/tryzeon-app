-- A size row was readable by anyone, so the sizes of an archived product stayed
-- public after its product was hidden. Reading products inside the policy runs
-- under the caller's own products policy, so a size is visible exactly when its
-- product is: shoppers see listed products' sizes, and an owner still sees the
-- sizes of their own archived products, which the store-side update relies on
-- when it reads the updated row back.

DROP POLICY "Anyone can view all product sizes" ON "public"."product_sizes";

CREATE POLICY "Sizes are visible with their product"
  ON "public"."product_sizes" FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM "public"."products" "p"
      WHERE "p"."id" = "product_sizes"."product_id"
    )
  );
