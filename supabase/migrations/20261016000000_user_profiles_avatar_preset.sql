-- A preset model becomes a reference instead of a copy. Choosing a preset used
-- to copy its image into `user-avatars` and store that copy's path, so nothing
-- could tell a preset from the user's own photo. `avatar_preset` now names the
-- preset (its image is R2 `presets/<id>.jpg`, derived from the id) and
-- `avatar_path` holds only the user's own photo; at most one is set.
--
-- Backfill: the app named its copies `<uid>/avatar/preset_<id>_<ms>.jpg`, so
-- those rows become references. LIFF named its copies by timestamp alone,
-- indistinguishable from an upload, so they stay as the user's own photo. The
-- replaced copies stay in storage until the one-off cleanup after deploy, since
-- SQL cannot delete storage objects.

CREATE TYPE "public"."preset_avatar" AS ENUM ('female', 'male');
ALTER TYPE "public"."preset_avatar" OWNER TO "postgres";

ALTER TABLE "public"."user_profiles"
  ADD COLUMN "avatar_preset" "public"."preset_avatar";

UPDATE "public"."user_profiles"
  SET "avatar_preset" = substring(
        "avatar_path" FROM '/avatar/preset_(female|male)_[0-9]+\.jpg$'
      )::"public"."preset_avatar",
      "avatar_path" = NULL
  WHERE "avatar_path" ~ (
    '^' || "user_id"::"text" || '/avatar/preset_(female|male)_[0-9]+\.jpg$'
  );

ALTER TABLE "public"."user_profiles"
  ADD CONSTRAINT "user_profiles_avatar_single_source"
  CHECK ("avatar_preset" IS NULL OR "avatar_path" IS NULL);
