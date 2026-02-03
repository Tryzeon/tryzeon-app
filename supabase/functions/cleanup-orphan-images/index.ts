
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async () => {
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    try {
        // 1️⃣ 清理 Wardrobe 孤兒圖片
        const { data: wardrobeOrphans, error: wardrobeError } = await supabase
            .rpc('find_orphan_wardrobe_images')

        if (wardrobeError) throw wardrobeError

        let wardrobeDeleted = 0
        if (wardrobeOrphans && wardrobeOrphans.length > 0) {
            const paths = wardrobeOrphans.map(item => item.image_path)
            const { error: removeError } = await supabase.storage
                .from('wardrobe-images')
                .remove(paths)

            if (removeError) throw removeError
            wardrobeDeleted = paths.length
        }

        // 2️⃣ 清理 Avatar 孤兒圖片
        const { data: avatarOrphans, error: avatarError } = await supabase
            .rpc('find_orphan_avatar_images')

        if (avatarError) throw avatarError

        let avatarDeleted = 0
        if (avatarOrphans && avatarOrphans.length > 0) {
            const paths = avatarOrphans.map(item => item.image_path)
            const { error: removeError } = await supabase.storage
                .from('user-avatars')
                .remove(paths)

            if (removeError) throw removeError
            avatarDeleted = paths.length
        }

        // 3️⃣ 清理 Store Logo 孤兒圖片
        const { data: storeLogoOrphans, error: storeLogoError } = await supabase
            .rpc('find_orphan_store_logos')

        if (storeLogoError) throw storeLogoError

        let storeLogoDeleted = 0
        if (storeLogoOrphans && storeLogoOrphans.length > 0) {
            const paths = storeLogoOrphans.map(item => item.image_path)
            const { error: removeError } = await supabase.storage
                .from('store-logos')
                .remove(paths)

            if (removeError) throw removeError
            storeLogoDeleted = paths.length
        }

        // 4️⃣ 清理 Store Product 孤兒圖片
        const { data: storeProductOrphans, error: storeProductError } = await supabase
            .rpc('find_orphan_store_products')

        if (storeProductError) throw storeProductError

        let storeProductDeleted = 0
        if (storeProductOrphans && storeProductOrphans.length > 0) {
            const paths = storeProductOrphans.map(item => item.image_path)
            const { error: removeError } = await supabase.storage
                .from('product-images')
                .remove(paths)

            if (removeError) throw removeError
            storeProductDeleted = paths.length
        }

        // 5️⃣ 返回詳細統計
        return new Response(JSON.stringify({
            wardrobe: wardrobeDeleted,
            avatars: avatarDeleted,
            store_logos: storeLogoDeleted,
            store_products: storeProductDeleted,
        }))

    } catch (error) {
        return new Response(JSON.stringify({
            error: error.message
        }), { status: 500 })
    }
})


/* DB Function Example:

CREATE OR REPLACE FUNCTION find_orphan_store_products()
RETURNS TABLE (image_path text)
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT o.name::text AS image_path
  FROM storage.objects o
  WHERE o.bucket_id = 'product-images'
  AND NOT EXISTS (
    SELECT 1 
    FROM public.products p 
    WHERE p.image_path = o.name
  );
END;
$$ LANGUAGE plpgsql;

*/