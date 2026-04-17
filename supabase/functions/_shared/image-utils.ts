import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/**
 * Downloads an image from Supabase storage and converts it to base64.
 * Infers the bucket name from the path.
 */
export async function fetchImageAsBase64(supabase: SupabaseClient, path: string): Promise<string> {
  const folderToBucketMap: Record<string, string> = {
    "wardrobe": "wardrobe-images",
    "products": "product-images",
    "avatar": "user-avatars",
  };

  const segments = path.split('/');
  const folder = segments.find(segment => folderToBucketMap.hasOwnProperty(segment));

  if (!folder) {
    throw new Error(`Invalid path structure: ${path}. No valid folder segment found. Expected one of: ${Object.keys(folderToBucketMap).join(", ")}`);
  }

  const bucket = folderToBucketMap[folder];

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
