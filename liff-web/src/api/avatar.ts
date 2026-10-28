import { currentUserId } from "../lib/auth";
import { JPEG_MIME, type JpegBlob } from "../lib/image";
import type { PresetAvatarId } from "../lib/presetAvatars";
import { supabase } from "../lib/supabase";
import {
  avatarColumns,
  type AvatarStore,
  avatarUploadPath,
  commitAvatar,
  parseStoredAvatar,
  type StoredAvatar,
} from "./avatar-wire";

const AVATARS_BUCKET = "user-avatars";
// Longer than the app's one hour: home stays mounted inside the tab shell, so
// the signed URL has to outlive the whole LIFF session rather than just lasting
// until the next remount.
const SIGNED_URL_TTL_SECONDS = 86400;

export async function setPresetAvatar(id: PresetAvatarId): Promise<StoredAvatar> {
  const next: StoredAvatar = { kind: "preset", id };
  await commitAvatar(avatarStore(await currentUserId()), next);
  return next;
}

export async function uploadAvatar(jpeg: JpegBlob): Promise<StoredAvatar> {
  const userId = await currentUserId();
  const path = avatarUploadPath(userId, Date.now());

  const { error } = await supabase.storage
    .from(AVATARS_BUCKET)
    .upload(path, jpeg, { contentType: JPEG_MIME, upsert: true });
  if (error) throw error;

  const next: StoredAvatar = { kind: "uploaded", path };
  await commitAvatar(avatarStore(userId), next);
  return next;
}

export async function avatarUrl(path: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from(AVATARS_BUCKET)
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
  if (error) throw error;
  return data.signedUrl;
}

function avatarStore(userId: string): AvatarStore {
  return {
    read: () => fetchStoredAvatar(userId),
    write: (avatar) => writeAvatar(userId, avatar),
    discard: discardUpload,
  };
}

async function fetchStoredAvatar(userId: string): Promise<StoredAvatar | null> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("avatar_path, avatar_preset")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  return data === null ? null : parseStoredAvatar(data);
}

async function writeAvatar(userId: string, avatar: StoredAvatar): Promise<void> {
  const { error } = await supabase
    .from("user_profiles")
    .update(avatarColumns(avatar))
    .eq("user_id", userId);
  if (error) throw error;
}

// A failed delete only orphans an object; the profile already points at the
// right model, so the save must not be reported as failed.
async function discardUpload(path: string): Promise<void> {
  try {
    const { error } = await supabase.storage.from(AVATARS_BUCKET).remove([path]);
    if (error) throw error;
  } catch (err) {
    console.error(`[avatar] could not delete ${path}:`, err);
  }
}
