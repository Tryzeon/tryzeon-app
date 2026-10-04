import { JPEG_EXTENSION, JPEG_MIME } from "./image";

export type Gender = "female" | "male";

export interface PresetAvatar {
  id: Gender;
  url: string;
  label: string;
}

export const PRESET_AVATARS: readonly PresetAvatar[] = [
  { id: "female", url: "/images/presets/female.jpg", label: "女性模特" },
  { id: "male", url: "/images/presets/male.jpg", label: "男性模特" },
];

export function presetsForGender(gender: Gender | null): readonly PresetAvatar[] {
  if (gender === null) return PRESET_AVATARS;
  return PRESET_AVATARS.filter((preset) => preset.id === gender);
}

export function parseGender(value: unknown): Gender | null {
  return value === "female" || value === "male" ? value : null;
}

export async function presetAvatarFile(preset: PresetAvatar): Promise<File> {
  const resp = await fetch(preset.url);
  if (!resp.ok) throw new Error(`failed to fetch preset avatar: ${resp.status}`);
  return new File([await resp.blob()], `preset_${preset.id}.${JPEG_EXTENSION}`, {
    type: JPEG_MIME,
  });
}
