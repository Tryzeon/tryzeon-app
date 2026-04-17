import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * Downloads an image from Supabase storage and converts it to base64.
 * Infers the bucket name from the path.
 */
export async function fetchImageAsBase64(supabase: SupabaseClient, path: string): Promise<string> {
  let bucket: string;
  
  // Robust bucket detection
  if (path.includes("wardrobe/")) {
    bucket = "wardrobe-images";
  } else if (path.includes("product/")) {
    bucket = "product-images";
  } else if (path.includes("avatar/")) {
    bucket = "user-avatars";
  } else {
    // Fallback or explicit check if path is just the filename and we know where it comes from
    // In this app, paths usually include the folder name
    throw new Error(`Cannot determine bucket from path: ${path}. Path must include folder name (wardrobe, product, or avatar).`);
  }

  const { data, error } = await supabase.storage.from(bucket).download(path);
  
  if (error) {
    throw new Error(`Failed to download image from ${bucket}/${path}: ${error.message}`);
  }

  if (!data) {
    throw new Error(`No data returned for image: ${bucket}/${path}`);
  }

  const arrayBuffer = await data.arrayBuffer();
  const uint8Array = new Uint8Array(arrayBuffer);
  
  // Efficient base64 conversion for Deno, avoiding stack limits
  return btoa(Array.from(uint8Array, (b) => String.fromCharCode(b)).join(""));
}
