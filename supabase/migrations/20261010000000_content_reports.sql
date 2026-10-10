-- A user can report an AI try-on result they find offensive from inside the
-- app (Google Play AI-Generated Content policy).
--
-- The target is a typed FK per content kind, only try-on generations today; a
-- future kind adds its own column and relaxes the NOT NULL. Only the
-- generation's owner can report it, so one generation has at most one report.
-- Clients get column-level INSERT only: the reporter comes from the session,
-- and reports cannot be read back. The ownership EXISTS runs under the caller's
-- RLS, which is why users can read their own `tryon_generations` rows.

CREATE TABLE "public"."content_reports" (
  "id" "uuid" PRIMARY KEY DEFAULT "gen_random_uuid"(),
  "reporter_id" "uuid" NOT NULL DEFAULT "auth"."uid"()
    REFERENCES "auth"."users"("id") ON DELETE CASCADE,
  "tryon_generation_id" "uuid" NOT NULL UNIQUE
    REFERENCES "public"."tryon_generations"("id") ON DELETE CASCADE,
  "created_at" timestamp with time zone NOT NULL DEFAULT "now"()
);

ALTER TABLE "public"."content_reports" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "public"."content_reports" FROM "anon", "authenticated";
GRANT INSERT ("tryon_generation_id") ON TABLE "public"."content_reports" TO "authenticated";

CREATE POLICY "Users report own succeeded generations" ON "public"."content_reports"
  FOR INSERT TO "authenticated"
  WITH CHECK (
    "reporter_id" = "auth"."uid"() AND
    EXISTS (
      SELECT 1 FROM "public"."tryon_generations" "g"
      WHERE "g"."id" = "content_reports"."tryon_generation_id"
        AND "g"."user_id" = "auth"."uid"()
        AND "g"."status" = 'succeeded'
    )
  );
