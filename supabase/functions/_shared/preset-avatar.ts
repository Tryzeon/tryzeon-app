import type { Enums } from "./database.types.ts";

export type PresetAvatarId = Enums<"preset_avatar">;

/**
 * The object under a preset's key is never replaced: a new image ships as a
 * new id, which is what lets the CDN cache it as immutable.
 */
export function presetAvatarKey(id: PresetAvatarId): string {
  return `presets/${id}.jpg`;
}
