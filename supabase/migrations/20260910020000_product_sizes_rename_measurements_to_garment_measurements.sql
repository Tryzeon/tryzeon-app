-- `product_sizes.measurements` said neither whose dimensions it held nor how
-- it related to `user_profiles.measurements`, the shopper's own body. The keys
-- inside were already renamed to garment vocabulary in 20260723000000; the
-- column now says the same thing, and leaves room beside it for the wearer's
-- side of the size chart.

ALTER TABLE "public"."product_sizes"
  RENAME COLUMN "measurements" TO "garment_measurements";
