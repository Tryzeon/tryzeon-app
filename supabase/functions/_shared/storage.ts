export const USER_AVATARS_BUCKET = "user-avatars";
export const WARDROBE_IMAGES_BUCKET = "wardrobe-images";

export type SupabaseImageBucket =
  | typeof USER_AVATARS_BUCKET
  | typeof WARDROBE_IMAGES_BUCKET;

export function publicImageUrl(baseUrl: string, key: string): string {
  return `${baseUrl.replace(/\/+$/, "")}/${key}`;
}

export function ownsUserObjectPath(userId: string, path: unknown): path is string {
  return typeof path === "string" && path.startsWith(`${userId}/`);
}
