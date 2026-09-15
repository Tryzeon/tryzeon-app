-- 'dress' becomes 'one_piece': a structural type for anything joined into a
-- single piece (dress, jumpsuit, overall), not just the dress. Every row and
-- category default on 'dress' follows the rename; the two 連身褲 products still
-- carry the 'pants' their category defaulted to before it was switched, and
-- move here.
--
-- Ships in lockstep with app 1.18.0: earlier installs still write 'dress' and
-- are locked out by the [:mav: 1.18.0] tag in that release's store listing.
--
-- wardrobe_items on 'pants' are left alone: nothing records whether a pair of
-- pants is a jumpsuit, so those need a person, not a migration.

ALTER TYPE "public"."garment_type" RENAME VALUE 'dress' TO 'one_piece';

UPDATE "public"."products" p SET "garment_type" = 'one_piece'
  FROM "public"."product_categories" c
  WHERE c."id" = p."category_id"
    AND c."code" = 'jumpsuit'
    AND p."garment_type" = 'pants';
