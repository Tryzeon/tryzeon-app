import { publicImageUrl } from "./publicImage";

export type Gender = "female" | "male";

export type PresetAvatarId = "female" | "male";

export interface PresetAvatar {
  id: PresetAvatarId;
  gender: Gender;
  label: string;
}

export const PRESET_AVATARS: readonly PresetAvatar[] = [
  { id: "female", gender: "female", label: "女性模特" },
  { id: "male", gender: "male", label: "男性模特" },
];

export function presetAvatarUrl(id: PresetAvatarId): string {
  return publicImageUrl(
    import.meta.env.VITE_R2_PUBLIC_IMAGES_BASE_URL as string,
    `presets/${id}.jpg`,
  );
}

export function presetsForGender(gender: Gender | null): readonly PresetAvatar[] {
  if (gender === null) return PRESET_AVATARS;
  return PRESET_AVATARS.filter((preset) => preset.gender === gender);
}

export function parseGender(value: unknown): Gender | null {
  return value === "female" || value === "male" ? value : null;
}
