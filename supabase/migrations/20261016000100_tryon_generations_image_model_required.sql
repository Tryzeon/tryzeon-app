-- Every try-on job now generates an image, video jobs included, so a succeeded
-- row always knows its image model. This supersedes the note in
-- 20261014000100_tryon_generations_models.sql: the animate job that left
-- `image_model` null is gone.
--
-- NOT VALID: rows that succeeded before models were recorded, and those left by
-- the retired animate job, keep their null. Succeeded rows are never updated
-- again, so the check only ever runs on new completions.

ALTER TABLE "public"."tryon_generations"
  ADD CONSTRAINT "tryon_generations_succeeded_image_model"
  CHECK ("status" <> 'succeeded' OR "image_model" IS NOT NULL) NOT VALID;
