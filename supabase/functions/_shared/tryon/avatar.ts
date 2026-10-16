import { presetAvatarKey } from "../preset-avatar.ts";
import { USER_AVATARS_BUCKET } from "../supabase-storage.ts";
import { getAvatar } from "../user-profile.ts";
import { MissingAvatarError } from "./errors.ts";
import type { ImageSource } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export async function resolveStoredAvatar(
  client: DbClient,
  userId: string,
): Promise<ImageSource> {
  const avatar = await getAvatar(client, userId);
  if (!avatar) throw new MissingAvatarError("no avatar on profile");
  return avatar.kind === "preset"
    ? { publicImageKey: presetAvatarKey(avatar.id) }
    : { bucket: USER_AVATARS_BUCKET, path: avatar.path };
}
