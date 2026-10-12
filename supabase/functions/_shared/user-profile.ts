import { ownsUserObjectPath } from "./storage.ts";
import { nonEmptyStr, textArrayValues } from "./text.ts";
import type { Enums } from "./database.types.ts";
import type { DbClient } from "./supabase.ts";

export const USER_PROFILES_TABLE = "user_profiles";

const AVATAR_PATH_COLUMN = "avatar_path";

const PROFILE_COLUMNS = "name, gender, age_range, style_preferences";

export interface UserProfile {
  name: string | null;
  gender: Enums<"user_gender"> | null;
  /** Raw bucket code (e.g. `25_34`); consumers own what it renders as. */
  ageRange: string | null;
  stylePreferences: string[];
}

/**
 * `avatar_path` is client-written free text, and the LINE adapter reads it on
 * the admin client with no storage policy beneath it. A path outside the
 * user's own folder is therefore reported as "no avatar" rather than resolved,
 * mirroring the `user_profiles_avatar_path_owner_check` constraint.
 */
export async function getAvatarPath(
  client: DbClient,
  userId: string,
): Promise<string | null> {
  const { data, error } = await client
    .from(USER_PROFILES_TABLE)
    .select(AVATAR_PATH_COLUMN)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`${AVATAR_PATH_COLUMN} lookup failed: ${error.message}`);
  }
  const path = data?.[AVATAR_PATH_COLUMN]?.trim();
  return ownsUserObjectPath(userId, path) ? path : null;
}

export async function getUserProfile(
  client: DbClient,
  userId: string,
): Promise<UserProfile | null> {
  const { data, error } = await client
    .from(USER_PROFILES_TABLE)
    .select(PROFILE_COLUMNS)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`user profile lookup failed: ${error.message}`);
  }
  if (!data) return null;

  return {
    name: nonEmptyStr(data.name),
    gender: data.gender,
    ageRange: nonEmptyStr(data.age_range),
    stylePreferences: textArrayValues(data.style_preferences),
  };
}
