
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async () => {
    const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    try {
        // 1️⃣ 清理 Wardrobe 孤兒圖片
        const { data: wardrobeOrphans } = await supabase
            .rpc('find_orphan_wardrobe_images')

        let wardrobeDeleted = 0
        if (wardrobeOrphans && wardrobeOrphans.length > 0) {
            const paths = wardrobeOrphans.map(item => item.image_path)
            const { error } = await supabase.storage
                .from('wardrobe')
                .remove(paths)

            if (!error) {
                wardrobeDeleted = paths.length
            }
        }

        // 2️⃣ 清理 Avatar 孤兒圖片
        const { data: avatarOrphans } = await supabase
            .rpc('find_orphan_avatar_images')

        let avatarDeleted = 0
        if (avatarOrphans && avatarOrphans.length > 0) {
            const paths = avatarOrphans.map(item => item.image_path)
            const { error } = await supabase.storage
                .from('avatars')
                .remove(paths)

            if (!error) {
                avatarDeleted = paths.length
            }
        }

        // 3️⃣ 返回詳細統計
        return new Response(JSON.stringify({
            wardrobe: wardrobeDeleted,
            avatars: avatarDeleted,
            total: wardrobeDeleted + avatarDeleted
        }))

    } catch (error) {
        return new Response(JSON.stringify({
            error: error.message
        }), { status: 500 })
    }
})
