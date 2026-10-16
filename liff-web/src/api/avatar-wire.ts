import { JPEG_EXTENSION } from "../lib/image";
import { PRESET_AVATARS, type PresetAvatarId } from "../lib/presetAvatars";

export type StoredAvatar =
  | { kind: "preset"; id: PresetAvatarId }
  | { kind: "uploaded"; path: string };

export type AvatarColumns = {
  avatar_path: string | null;
  avatar_preset: PresetAvatarId | null;
};

export interface AvatarStore {
  read(): Promise<StoredAvatar | null>;
  write(avatar: StoredAvatar): Promise<void>;
  discard(path: string): Promise<void>;
}

export function parseStoredAvatar(
  row: { avatar_path: unknown; avatar_preset: unknown },
): StoredAvatar | null {
  const preset = PRESET_AVATARS.find((p) => p.id === row.avatar_preset);
  if (preset !== undefined) return { kind: "preset", id: preset.id };

  const path = row.avatar_path;
  return typeof path === "string" && path.length > 0 ? { kind: "uploaded", path } : null;
}

export function avatarColumns(avatar: StoredAvatar): AvatarColumns {
  return avatar.kind === "preset"
    ? { avatar_path: null, avatar_preset: avatar.id }
    : { avatar_path: avatar.path, avatar_preset: null };
}

export function supersededUpload(
  previous: StoredAvatar | null,
  next: StoredAvatar,
): string | null {
  if (previous?.kind !== "uploaded") return null;
  if (next.kind === "uploaded" && next.path === previous.path) return null;
  return previous.path;
}

/** Reads the stored model right before the write rather than trusting the one
 * loaded at session start: the app may have replaced it since, and only the
 * photo this write actually replaces may be deleted. */
export async function commitAvatar(store: AvatarStore, next: StoredAvatar): Promise<void> {
  let previous: StoredAvatar | null;
  try {
    previous = await store.read();
    await store.write(next);
  } catch (err) {
    if (next.kind === "uploaded") await store.discard(next.path);
    throw err;
  }
  const superseded = supersededUpload(previous, next);
  if (superseded !== null) await store.discard(superseded);
}

/** The first segment must be the session's userId: the bucket policy demands
 * `(storage.foldername(name))[1] = auth.uid()`, and any other folder makes the
 * upload fail. */
export function avatarUploadPath(userId: string, timestamp: number): string {
  return `${userId}/avatar/${timestamp}.${JPEG_EXTENSION}`;
}
