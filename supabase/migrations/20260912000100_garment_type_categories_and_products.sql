-- Categories get a stable machine key (code), the list is reshaped, and every
-- product records the garment_type it was published under. 家居服 and 套裝 are
-- removed: the products that lived there were inventoried on 2026-09-12 and are
-- recategorised or deleted by id below; anything else still referencing them
-- aborts the migration rather than being guessed at.

-- 1. Category rows
UPDATE "public"."product_categories" SET "name" = '裙子'       WHERE "name" = '裙裝';
UPDATE "public"."product_categories" SET "name" = '洋裝·連身裙' WHERE "name" = '洋裝';

INSERT INTO "public"."product_categories" ("name", "gender", "order", "default_garment_type")
VALUES ('連身褲', 'unisex', 113, 'pants')
ON CONFLICT ("name") DO NOTHING;

-- 2. Products inventoried in 套裝 / 家居服 (active rows as of 2026-09-12; the
--    only archived product belongs to 襯衫·POLO衫 and is untouched)
UPDATE "public"."products"
  SET "category_id" = (SELECT "id" FROM "public"."product_categories" WHERE "name" = '連身褲')
  WHERE "id" IN (
    '80a6f209-3263-4f96-94ef-6bb10c9a3a97',  -- 081012綠色荷葉邊吊帶連身寬褲
    '32917784-b615-4c11-b440-e62064e69283'   -- 092732藍色寬鬆棉質丹寧吊帶褲
  );

UPDATE "public"."products"
  SET "category_id" = (SELECT "id" FROM "public"."product_categories" WHERE "name" = '長褲')
  WHERE "id" IN (
    '9e646bfb-a701-4ad3-bfa2-e0644aa53684',  -- 062639深藍花花寬鬆長褲
    '0da0df88-14ae-4dd8-88a9-a392fe724cff',  -- 070215淺藍花卉印花居長褲
    '5ab6c72d-64bc-4bbe-9db6-dc22e9d3200f',  -- 062663紫色樹懶印花棉質寬鬆家居長褲
    'fd9286dc-aedc-446c-bbc7-ed2f9febb6a7'   -- 062663米色樹懶印花寬鬆家居褲
  );

UPDATE "public"."products"
  SET "category_id" = (SELECT "id" FROM "public"."product_categories" WHERE "name" = '裙子')
  WHERE "id" = '286c34cb-2e34-4ad3-bab3-c3ca00bd2f78';  -- 062208嚕嚕米印花寬鬆棉質長裙

UPDATE "public"."products"
  SET "category_id" = (SELECT "id" FROM "public"."product_categories" WHERE "name" = '襯衫·POLO衫')
  WHERE "id" = '8edb512b-e845-4237-b8d2-2ec78a868cd4';  -- 綠藍條紋寬鬆棉質POLO衫

-- Loungewear sets have no category in the new list; product_sizes and analytics
-- rows cascade. R2 images are not cleaned up here.
DELETE FROM "public"."products" WHERE "id" IN (
  '7548601c-851d-4e3e-98cb-1ba62456fbb4',  -- 000000SNIDEL粉大櫻桃居家服
  '96a22fb8-2048-41c3-b2ea-9f3d224526fd',  -- 080912SNIDEL粉滿版櫻桃居家服
  '03b4b839-e590-4230-aeb8-2a7e45129858',  -- 092208白CareBears居家服
  '5aa9b1e9-406d-4421-b023-fd26ce679a00',  -- 092208粉CareBears居家服
  'af767ade-ebe3-401e-8c7c-35205a0d8ae5'   -- 092208藍紫CareBears居家服
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM "public"."products" p
    JOIN "public"."product_categories" c ON c."id" = p."category_id"
    WHERE c."name" IN ('套裝', '家居服')
  ) THEN
    RAISE EXCEPTION 'products still reference 套裝/家居服; recategorise them before migrating';
  END IF;
END $$;

DELETE FROM "public"."product_categories" WHERE "name" IN ('套裝', '家居服');

-- 3. Stable code
ALTER TABLE "public"."product_categories" ADD COLUMN "code" "text";

UPDATE "public"."product_categories" SET "code" = CASE "name"
  WHEN '襯衫·POLO衫'   THEN 'shirt_polo'
  WHEN '背心·無袖上衣' THEN 'vest'
  WHEN '針織·毛衣'     THEN 'knit_sweater'
  WHEN '大學T·連帽T'   THEN 'hoodie'
  WHEN '長袖'          THEN 'long_sleeve'
  WHEN '短袖'          THEN 'short_sleeve'
  WHEN '長T'           THEN 'long_sleeve'
  WHEN '短T'           THEN 'short_sleeve'
  WHEN '長褲'          THEN 'trousers'
  WHEN '短褲'          THEN 'shorts'
  WHEN '連身褲'        THEN 'jumpsuit'
  WHEN '裙子'          THEN 'skirt'
  WHEN '外套'          THEN 'outerwear'
  WHEN '洋裝·連身裙'   THEN 'dress'
END;

DO $$
DECLARE missing text;
BEGIN
  SELECT string_agg("name", ', ') INTO missing
  FROM "public"."product_categories" WHERE "code" IS NULL;
  IF missing IS NOT NULL THEN
    RAISE EXCEPTION 'product_categories without a code: %', missing;
  END IF;
END $$;

ALTER TABLE "public"."product_categories"
  ALTER COLUMN "code" SET NOT NULL,
  ADD CONSTRAINT "product_categories_code_key" UNIQUE ("code");

-- 4. default_garment_type is required
ALTER TABLE "public"."product_categories"
  ALTER COLUMN "default_garment_type" SET NOT NULL;

-- 5. products.garment_type, seeded from the category the product sits in now
ALTER TABLE "public"."products" ADD COLUMN "garment_type" "public"."garment_type";

UPDATE "public"."products" p
  SET "garment_type" = c."default_garment_type"
  FROM "public"."product_categories" c
  WHERE c."id" = p."category_id";

ALTER TABLE "public"."products"
  ALTER COLUMN "garment_type" SET NOT NULL;

CREATE INDEX "idx_products_garment_type" ON "public"."products" USING "btree" ("garment_type");
