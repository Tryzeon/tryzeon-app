-- Which models produced a generation's result, so models can be compared on
-- outcome and rating. Set when the row succeeds, since only then is it known
-- which one answered: the standard engine may answer from its fallback. An
-- animate job generates no image and an image job no video, so either model
-- may stay null on a succeeded row.

ALTER TABLE "public"."tryon_generations"
  ADD COLUMN "image_model" "text",
  ADD COLUMN "video_model" "text";
