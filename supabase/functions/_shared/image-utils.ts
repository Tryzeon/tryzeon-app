import { encodeBase64 } from "@std/encoding/base64";
import { downloadPublicImageFromR2 } from "./r2.ts";
import type { SupabaseImageBucket } from "./storage.ts";
import type { DbClient } from "./supabase.ts";

export async function downloadStorageImageAsBase64(
  supabase: DbClient,
  bucket: SupabaseImageBucket,
  path: string,
): Promise<string> {
  const { data, error } = await supabase.storage.from(bucket).download(path);

  if (error) {
    throw new Error(`Failed to download image from ${bucket}/${path}: ${error.message}`);
  }

  if (!data) {
    throw new Error(`No data returned for image: ${bucket}/${path}`);
  }

  const arrayBuffer = await data.arrayBuffer();
  return encodeBase64(arrayBuffer);
}

export async function downloadPublicImageAsBase64(key: string): Promise<string> {
  return encodeBase64(await downloadPublicImageFromR2(key));
}

export function detectMimeType(base64Data: string): string {
  const header = atob(base64Data.slice(0, 16));
  if (header.startsWith("\x89PNG")) return "image/png";
  if (header.startsWith("\xFF\xD8\xFF")) return "image/jpeg";
  if (header.slice(0, 4) === "RIFF" && header.slice(8, 12) === "WEBP") {
    return "image/webp";
  }
  return "image/jpeg";
}

export function mimeTypeToExtension(mimeType: string): string {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "image/jpeg":
    default:
      return "jpg";
  }
}
