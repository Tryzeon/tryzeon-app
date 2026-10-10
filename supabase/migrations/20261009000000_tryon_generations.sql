-- Every try-on generation gets a row: who ran it, in which mode, and how it
-- ended.
--
-- Written on the service role only, like `log_tryon_events`: the LINE adapter
-- has no session, so the writer names the user itself. Users may read their
-- own rows.
--
-- The result is kept as an R2 object key, not a URL: try-on buckets are
-- private and the URLs handed to clients are signed for 7 days, so a reader
-- re-signs from the key. The bucket follows from `mode`.

CREATE TYPE "public"."tryon_generation_mode" AS ENUM ('image', 'video');
CREATE TYPE "public"."tryon_generation_status" AS ENUM ('pending', 'succeeded', 'failed');

CREATE TABLE "public"."tryon_generations" (
  "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
  "user_id" "uuid" NOT NULL REFERENCES "auth"."users"("id") ON DELETE CASCADE,
  "mode" "public"."tryon_generation_mode" NOT NULL,
  "status" "public"."tryon_generation_status" NOT NULL DEFAULT 'pending',
  "result_key" "text",
  "error_message" "text",
  "created_at" timestamp with time zone NOT NULL DEFAULT "now"(),
  "completed_at" timestamp with time zone,
  CONSTRAINT "tryon_generations_outcome" CHECK (
    ("status" = 'pending'   AND "result_key" IS NULL     AND "completed_at" IS NULL) OR
    ("status" = 'succeeded' AND "result_key" IS NOT NULL AND "completed_at" IS NOT NULL) OR
    ("status" = 'failed'    AND "result_key" IS NULL     AND "completed_at" IS NOT NULL)
  )
);

CREATE INDEX "tryon_generations_user_id_created_at_idx"
  ON "public"."tryon_generations" ("user_id", "created_at" DESC);

ALTER TABLE "public"."tryon_generations" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "public"."tryon_generations" FROM "anon", "authenticated";
GRANT SELECT ON TABLE "public"."tryon_generations" TO "authenticated";

CREATE POLICY "Users read own generations" ON "public"."tryon_generations"
  FOR SELECT TO "authenticated"
  USING ("user_id" = "auth"."uid"());
