import { supabase } from "../lib/supabase";

const WARDROBE_IMAGES_BUCKET = "wardrobe-images";
const SIGNED_URL_TTL_SECONDS = 86400;

export async function wardrobeImageUrl(path: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from(WARDROBE_IMAGES_BUCKET)
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
  if (error) throw error;
  return data.signedUrl;
}
