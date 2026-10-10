-- Why a disliked try-on fell short, so pipeline work can target the commonest
-- failures: either one picked `reason` or a typed `comment`. Both ride on the
-- rating row: clearing the rating deletes them with it, and a switch to a like
-- sends them as null in the same upsert. `reason` is plain text rather than an
-- enum while the list is still settling: the app owns the vocabulary.

ALTER TABLE "public"."tryon_ratings"
  ADD COLUMN "reason" "text",
  ADD COLUMN "comment" "text",
  ADD CONSTRAINT "tryon_ratings_explained_only_on_dislike"
    CHECK ("rating" = 'dislike' OR ("reason" IS NULL AND "comment" IS NULL));

GRANT INSERT ("reason", "comment"), UPDATE ("reason", "comment")
  ON TABLE "public"."tryon_ratings" TO "authenticated";
