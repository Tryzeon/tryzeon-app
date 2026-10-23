-- The 21 style tags were hard for shoppers to pick from and mixed regions
-- (japanese, korean, …) with actual styles. They become the 13 styles the app
-- now offers. Eight keep their spelling, the rest fold into the closest new
-- style, and the regional tags have no counterpart and are dropped. Both
-- columns that store the vocabulary are rewritten; a row that ends up with no
-- style becomes NULL, as if never tagged. The updated_at triggers are paused
-- so a vocabulary rename does not read as an edit.

CREATE FUNCTION "public"."convert_legacy_styles"("legacy" "text"[])
RETURNS "text"[]
LANGUAGE "sql" IMMUTABLE
AS $$
  SELECT array_agg("new" ORDER BY "ord")
  FROM (
    SELECT DISTINCT ON ("new") "m"."new", "u"."ord"
    FROM unnest("legacy") WITH ORDINALITY AS "u"("old", "ord")
    JOIN (
      VALUES
        ('minimalist', 'basic'),
        ('casual', 'casual'),
        ('business', 'business'),
        ('elegant', 'elegant'),
        ('mature', 'elegant'),
        ('sweet', 'sweet'),
        ('streetwear', 'streetwear'),
        ('sporty', 'sporty'),
        ('functional', 'sporty'),
        ('vintage', 'vintage'),
        ('preppy', 'preppy'),
        ('neutral', 'edgy'),
        ('artsy', 'natural'),
        ('literary', 'natural'),
        ('lazy', 'natural'),
        ('spicy', 'party'),
        ('basic', 'basic'),
        ('edgy', 'edgy'),
        ('natural', 'natural'),
        ('party', 'party'),
        ('homewear', 'homewear')
    ) AS "m"("old", "new") ON "m"."old" = "u"."old"
    ORDER BY "new", "ord"
  ) AS "first_occurrence";
$$;

ALTER TABLE "public"."products" DISABLE TRIGGER "trg_products_updated_at";
UPDATE "public"."products"
SET "styles" = "public"."convert_legacy_styles"("styles")
WHERE "styles" IS NOT NULL
  AND "styles" IS DISTINCT FROM "public"."convert_legacy_styles"("styles");
ALTER TABLE "public"."products" ENABLE TRIGGER "trg_products_updated_at";

ALTER TABLE "public"."user_profiles" DISABLE TRIGGER "trg_user_profiles_updated_at";
UPDATE "public"."user_profiles"
SET "style_preferences" = "public"."convert_legacy_styles"("style_preferences")
WHERE "style_preferences" IS NOT NULL
  AND "style_preferences" IS DISTINCT FROM "public"."convert_legacy_styles"("style_preferences");
ALTER TABLE "public"."user_profiles" ENABLE TRIGGER "trg_user_profiles_updated_at";

DROP FUNCTION "public"."convert_legacy_styles"("text"[]);
