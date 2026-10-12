-- The owner comes from the session, so the client no longer sends `user_id` on
-- insert. The INSERT policy still checks it against auth.uid().

ALTER TABLE "public"."wardrobe_items"
  ALTER COLUMN "user_id" SET DEFAULT "auth"."uid"();
