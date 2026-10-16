import type { StoredAvatar } from "../api/avatar-wire";
import { presetAvatarUrl, type PresetAvatarId } from "../lib/presetAvatars";

export type AvatarStatus = "loading" | "ready" | "error";

/** [savedAs] stays null until the upload lands; only that path's signature may
 * retire the preview, so a slower signature for an earlier save cannot clear
 * the preview of a later one. */
export type AvatarPreview =
  | { kind: "preset"; id: PresetAvatarId }
  | { kind: "upload"; objectUrl: string; savedAs: string | null };

export type SignedAvatar = { path: string; url: string | null };

export function shownUrl(
  preview: AvatarPreview | null,
  avatar: StoredAvatar | null,
  signed: SignedAvatar | null,
): string | null {
  if (preview !== null) {
    return preview.kind === "preset" ? presetAvatarUrl(preview.id) : preview.objectUrl;
  }
  if (avatar === null) return null;
  if (avatar.kind === "preset") return presetAvatarUrl(avatar.id);
  return signed?.path === avatar.path ? signed.url : null;
}

export function avatarStatus(
  avatar: StoredAvatar | null,
  signed: SignedAvatar | null,
): AvatarStatus {
  if (avatar?.kind !== "uploaded") return "ready";
  if (signed?.path !== avatar.path) return "loading";
  return signed.url === null ? "error" : "ready";
}

export function settleOnSave(
  preview: AvatarPreview | null,
  saved: StoredAvatar,
): AvatarPreview | null {
  if (preview?.kind !== "upload" || saved.kind !== "uploaded") return null;
  return { ...preview, savedAs: saved.path };
}

export function settleOnSigned(
  preview: AvatarPreview | null,
  path: string,
): AvatarPreview | null {
  return preview?.kind === "upload" && preview.savedAs === path ? null : preview;
}
