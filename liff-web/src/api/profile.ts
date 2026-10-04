import { type Gender, parseGender } from "../lib/presetAvatars";
import { supabase } from "../lib/supabase";

export interface AvatarProfile {
  avatarPath: string | null;
  gender: Gender | null;
}

export async function fetchAvatarProfile(userId: string): Promise<AvatarProfile> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("avatar_path, gender")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;

  const path = data?.avatar_path;
  return {
    avatarPath: typeof path === "string" && path.length > 0 ? path : null,
    gender: parseGender(data?.gender),
  };
}
