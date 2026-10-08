-- Leftovers from the Supabase Storage era that nothing calls any more.
--
-- Product images and store logos moved to R2; only the `user-avatars` and
-- `wardrobe-images` buckets are still referenced by any client. The
-- `find_orphan_*` functions lost their only caller with the
-- cleanup-orphan-images Edge Function, yet stayed SECURITY DEFINER and
-- executable by `anon`, exposing stored object names (prefixed by user id).
-- `find_orphan_product_images` was already broken (it reads
-- `products.image_path`, which became `image_paths`), and
-- `list_migration_objects` was a one-off helper for the R2 move.
--
-- The legacy buckets themselves (`avatars`, `store_logos`, `store-logos`,
-- `store_products`, `product-images`) and their objects are not removed here;
-- Supabase blocks direct deletes on storage tables, so empty and delete them
-- from the dashboard.

DROP FUNCTION IF EXISTS public.find_orphan_avatar_images();
DROP FUNCTION IF EXISTS public.find_orphan_wardrobe_images();
DROP FUNCTION IF EXISTS public.find_orphan_product_images();
DROP FUNCTION IF EXISTS public.find_orphan_store_logos();
DROP FUNCTION IF EXISTS public.list_migration_objects(text[], integer, integer);

DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_2" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_3" ON storage.objects;
DROP POLICY IF EXISTS "Owner Access Logos" ON storage.objects;
DROP POLICY IF EXISTS "Public Access Logos" ON storage.objects;
DROP POLICY IF EXISTS "Owner Access Products" ON storage.objects;
DROP POLICY IF EXISTS "Public Access Products" ON storage.objects;
DROP POLICY IF EXISTS "Product Images - Owner Access" ON storage.objects;
DROP POLICY IF EXISTS "Product Images - Public Read" ON storage.objects;
