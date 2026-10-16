import { assertEquals, assertRejects } from "@std/assert";
import { resolveStoredAvatar } from "./avatar.ts";
import { MissingAvatarError } from "./errors.ts";
import { USER_AVATARS_BUCKET } from "../supabase-storage.ts";
import type { DbClient } from "../supabase.ts";

function fakeAdmin(row: Record<string, unknown>): DbClient {
  const chain = {
    eq: () => chain,
    maybeSingle: () => Promise.resolve({ data: row, error: null }),
  };
  return { from: () => ({ select: () => chain }) } as unknown as DbClient;
}

Deno.test("a preset avatar resolves to its public image key", async () => {
  const admin = fakeAdmin({
    user_id: "u1",
    avatar_path: null,
    avatar_preset: "male",
  });
  assertEquals(await resolveStoredAvatar(admin, "u1"), {
    publicImageKey: "presets/male.jpg",
  });
});

Deno.test("an uploaded avatar resolves to its object in the avatars bucket", async () => {
  const admin = fakeAdmin({
    user_id: "u1",
    avatar_path: "u1/avatar/1.jpg",
    avatar_preset: null,
  });
  assertEquals(await resolveStoredAvatar(admin, "u1"), {
    bucket: USER_AVATARS_BUCKET,
    path: "u1/avatar/1.jpg",
  });
});

Deno.test("a profile with neither source is a missing avatar", async () => {
  const admin = fakeAdmin({
    user_id: "u1",
    avatar_path: null,
    avatar_preset: null,
  });
  await assertRejects(
    () => resolveStoredAvatar(admin, "u1"),
    MissingAvatarError,
  );
});
