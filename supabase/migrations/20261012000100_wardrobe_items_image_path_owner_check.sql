-- image_path was free text bounded only by RLS on user_id, so a user could
-- point their own row at another user's storage key and have an admin-client
-- reader (the LINE webhook) sign a URL for it. The storage policies already
-- confine uploads to `<uid>/…`; this restates that folder rule on the row so
-- no reader has to remember it. Same check as ownsWardrobeImagePath in
-- supabase/functions/_shared/storage.ts.

ALTER TABLE "public"."wardrobe_items"
  ADD CONSTRAINT "wardrobe_items_image_path_owner_check"
  CHECK (starts_with("image_path", "user_id"::text || '/'));
