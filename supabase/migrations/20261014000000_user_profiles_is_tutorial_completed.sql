-- Existing rows take the first default (true) so only accounts created after
-- this migration see the first try-on tutorial.
ALTER TABLE "public"."user_profiles"
  ADD COLUMN "is_tutorial_completed" boolean NOT NULL DEFAULT true;

ALTER TABLE "public"."user_profiles"
  ALTER COLUMN "is_tutorial_completed" SET DEFAULT false;
