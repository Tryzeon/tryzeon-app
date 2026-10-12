-- Same bug class as 20261012000100 on wardrobe_items.image_path: avatar_path
-- is free text bounded only by RLS on user_id, so a user could point their own
-- profile at another user's object and have an admin-client reader (the LINE
-- try-on) download it under the service role. The storage policies already
-- confine uploads to `<uid>/avatar/…`; this restates that folder rule on the
-- row. Same check as ownsUserObjectPath in
-- supabase/functions/_shared/storage.ts.
--
-- A row that already violates the rule names an object its owner cannot read
-- through any client, so it is either broken or hostile; either way the only
-- usable value is "no avatar".

UPDATE "public"."user_profiles"
  SET "avatar_path" = NULL
  WHERE "avatar_path" IS NOT NULL
    AND NOT starts_with("avatar_path", "user_id"::text || '/');

ALTER TABLE "public"."user_profiles"
  ADD CONSTRAINT "user_profiles_avatar_path_owner_check"
  CHECK ("avatar_path" IS NULL OR starts_with("avatar_path", "user_id"::text || '/'));
