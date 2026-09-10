-- A size chart's "適合身高 160–170 / 體重 50–60" line: the body a size is
-- published as fitting, as opposed to `garment_measurements`, which is the garment's
-- own dimensions. Kept as its own column rather than more keys inside
-- `garment_measurements` because the two answer different questions (a garment waist
-- of 65 vs. "fits waists 63–66") and because these are ranges, not scalars.
--
-- Keys are the app's BodyMeasurementType values (height, weight, shoulder,
-- chest, waist, hips, thigh), each `{"min": n, "max": n}` in that type's own
-- unit (cm; kg for weight). Sparse: stores publish only what they state.
--
-- `list_shop_products` aggregates `jsonb_agg(v)` of the whole row and the app
-- selects `product_sizes(*)`, so neither needs a change.

ALTER TABLE "public"."product_sizes"
  ADD COLUMN "body_measurement_ranges" "jsonb";
