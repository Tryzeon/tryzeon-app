-- A user's like or dislike of a try-on result, kept to compare how satisfying
-- different VTON pipeline changes turn out. One rating per generation: the
-- generation already names its owner, so ownership is checked through it and
-- the row goes with the generation (and so with the account).
--
-- The client writes through PostgREST upsert, which sets every sent column on
-- conflict — hence UPDATE on `tryon_generation_id` as well as `rating`, with
-- the same ownership check on the new row. Clearing a rating deletes the row.

CREATE TYPE "public"."tryon_rating" AS ENUM ('like', 'dislike');

CREATE TABLE "public"."tryon_ratings" (
  "tryon_generation_id" "uuid" PRIMARY KEY
    REFERENCES "public"."tryon_generations"("id") ON DELETE CASCADE,
  "rating" "public"."tryon_rating" NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT "now"(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT "now"()
);

CREATE OR REPLACE TRIGGER "trg_tryon_ratings_updated_at" BEFORE UPDATE ON "public"."tryon_ratings"
  FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();

ALTER TABLE "public"."tryon_ratings" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "public"."tryon_ratings" FROM "anon", "authenticated";
GRANT SELECT, DELETE ON TABLE "public"."tryon_ratings" TO "authenticated";
GRANT INSERT ("tryon_generation_id", "rating"), UPDATE ("tryon_generation_id", "rating")
  ON TABLE "public"."tryon_ratings" TO "authenticated";

CREATE POLICY "Users read own ratings" ON "public"."tryon_ratings"
  FOR SELECT TO "authenticated"
  USING (EXISTS (
    SELECT 1 FROM "public"."tryon_generations" "g"
    WHERE "g"."id" = "tryon_ratings"."tryon_generation_id"
      AND "g"."user_id" = "auth"."uid"()
  ));

CREATE POLICY "Users rate own succeeded generations" ON "public"."tryon_ratings"
  FOR INSERT TO "authenticated"
  WITH CHECK (EXISTS (
    SELECT 1 FROM "public"."tryon_generations" "g"
    WHERE "g"."id" = "tryon_ratings"."tryon_generation_id"
      AND "g"."user_id" = "auth"."uid"()
      AND "g"."status" = 'succeeded'
  ));

CREATE POLICY "Users change own ratings" ON "public"."tryon_ratings"
  FOR UPDATE TO "authenticated"
  USING (EXISTS (
    SELECT 1 FROM "public"."tryon_generations" "g"
    WHERE "g"."id" = "tryon_ratings"."tryon_generation_id"
      AND "g"."user_id" = "auth"."uid"()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "public"."tryon_generations" "g"
    WHERE "g"."id" = "tryon_ratings"."tryon_generation_id"
      AND "g"."user_id" = "auth"."uid"()
      AND "g"."status" = 'succeeded'
  ));

CREATE POLICY "Users clear own ratings" ON "public"."tryon_ratings"
  FOR DELETE TO "authenticated"
  USING (EXISTS (
    SELECT 1 FROM "public"."tryon_generations" "g"
    WHERE "g"."id" = "tryon_ratings"."tryon_generation_id"
      AND "g"."user_id" = "auth"."uid"()
  ));
