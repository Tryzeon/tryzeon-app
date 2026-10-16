import { type Gender, parseGender } from "../lib/presetAvatars";
import { supabase } from "../lib/supabase";
import { parseStoredAvatar, type StoredAvatar } from "./avatar-wire";

export interface AvatarProfile {
  avatar: StoredAvatar | null;
  gender: Gender | null;
}

export async function fetchAvatarProfile(userId: string): Promise<AvatarProfile> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("avatar_path, avatar_preset, gender")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  if (data === null) return { avatar: null, gender: null };

  return {
    avatar: parseStoredAvatar(data),
    gender: parseGender(data.gender),
  };
}
