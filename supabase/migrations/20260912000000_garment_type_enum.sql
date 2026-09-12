-- wardrobe_category becomes garment_type: a structural type that decides which
-- size-chart dimensions a garment has, held directly by wardrobe_items and (from
-- the next migration) products. Value set:
--   top       -> top
--   bottoms   -> pants
--   outerwear -> outerwear
--   sets      -> removed (wardrobe_items -> others; 套裝 parked on others until
--                the next migration deletes the category)
--   others    -> others
--   (new)        skirt, dress
--
-- Postgres cannot drop an enum value in place, and the type is referenced by two
-- columns plus idx_wardrobe_items_category. Both columns go through text, the
-- data is remapped, the type is rebuilt, and the columns are cast back — one
-- transaction, no ADD VALUE commit boundary needed.

ALTER TABLE "public"."product_categories"
  ALTER COLUMN "wardrobe_category" TYPE "text" USING "wardrobe_category"::"text";
ALTER TABLE "public"."wardrobe_items"
  ALTER COLUMN "category" TYPE "text" USING "category"::"text";

UPDATE "public"."wardrobe_items" SET "category" = 'pants'  WHERE "category" = 'bottoms';
UPDATE "public"."wardrobe_items" SET "category" = 'others' WHERE "category" = 'sets';

UPDATE "public"."product_categories" SET "wardrobe_category" = 'pants'
  WHERE "wardrobe_category" = 'bottoms';
UPDATE "public"."product_categories" SET "wardrobe_category" = 'skirt' WHERE "name" = '裙裝';
UPDATE "public"."product_categories" SET "wardrobe_category" = 'dress' WHERE "name" = '洋裝';
UPDATE "public"."product_categories" SET "wardrobe_category" = 'others'
  WHERE "wardrobe_category" = 'sets';

DROP TYPE "public"."wardrobe_category";

CREATE TYPE "public"."garment_type" AS ENUM (
  'top',
  'outerwear',
  'pants',
  'skirt',
  'dress',
  'others'
);
ALTER TYPE "public"."garment_type" OWNER TO "postgres";

ALTER TABLE "public"."product_categories"
  ALTER COLUMN "wardrobe_category" TYPE "public"."garment_type"
  USING "wardrobe_category"::"public"."garment_type";
ALTER TABLE "public"."wardrobe_items"
  ALTER COLUMN "category" TYPE "public"."garment_type"
  USING "category"::"public"."garment_type";

ALTER TABLE "public"."product_categories"
  RENAME COLUMN "wardrobe_category" TO "default_garment_type";
ALTER TABLE "public"."wardrobe_items"
  RENAME COLUMN "category" TO "garment_type";
ALTER INDEX "public"."idx_wardrobe_items_category"
  RENAME TO "idx_wardrobe_items_garment_type";
