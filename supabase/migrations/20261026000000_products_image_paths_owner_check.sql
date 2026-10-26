-- image_paths was free text bounded only by RLS on store_id, so a store owner
-- could point their own product at another store's R2 key and have try-on, LINE
-- cards and chat serve it as theirs. Each path must now be a single file in the
-- product's own folder, `stores/<store_id>/products/<product_id>/<name>.<ext>`.
-- The name is one segment with no dots or slashes, so `..` segments that URL
-- resolvers would collapse into another store's folder cannot pass. It is not
-- pinned to a uuid: store-images names files by uuid, but older uploads were
-- named by millisecond timestamp and are still live.
--
-- A CHECK cannot hold a subquery, so the per-element test lives in an IMMUTABLE
-- function. A CHECK runs its function as the writing role, so only the roles
-- that write products keep EXECUTE; anon has no use for it.

CREATE FUNCTION "public"."product_image_paths_owned"(
  "paths" "text"[],
  "store_id" "uuid",
  "product_id" "uuid"
)
RETURNS boolean
LANGUAGE "sql" IMMUTABLE
SET "search_path" = ''
AS $$
  SELECT coalesce(
    bool_and(
      p IS NOT NULL
      AND p ~ (
        '^stores/' || store_id || '/products/' || product_id
        || '/[0-9a-z-]+\.(jpg|png|webp)$'
      )
    ),
    true
  )
  FROM unnest(paths) AS p;
$$;

REVOKE EXECUTE ON FUNCTION "public"."product_image_paths_owned"("text"[], "uuid", "uuid")
  FROM PUBLIC, "anon";

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_image_paths_owner_check"
  CHECK ("public"."product_image_paths_owned"("image_paths", "store_id", "id"));
