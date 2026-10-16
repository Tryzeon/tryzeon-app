import { assertEquals, assertRejects } from "@std/assert";
import { getAvatar } from "./user-profile.ts";
import type { DbClient } from "./supabase.ts";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

function fakeAdmin(stub: LookupStub) {
  const filters: Array<[string, string]> = [];
  const admin = {
    from: (_table: string) => ({
      select: () => {
        const chain = {
          eq: (column: string, value: string) => {
            filters.push([column, value]);
            return chain;
          },
          maybeSingle: () => {
            const row = stub.row;
            const match = row !== null &&
              filters.every(([column, value]) => row[column] === value);
            return Promise.resolve({
              data: match ? row : null,
              error: stub.error ?? null,
            });
          },
        };
        return chain;
      },
    }),
  } as unknown as DbClient;
  return { admin, filters };
}

Deno.test("getAvatar reads a preset as its id", async () => {
  const { admin, filters } = fakeAdmin({
    row: { user_id: "u1", avatar_path: null, avatar_preset: "female" },
  });
  assertEquals(await getAvatar(admin, "u1"), { kind: "preset", id: "female" });
  assertEquals(filters, [["user_id", "u1"]]);
});

Deno.test("getAvatar reads an uploaded photo in the user's own folder", async () => {
  const { admin, filters } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u1/avatar/1.jpg", avatar_preset: null },
  });
  assertEquals(await getAvatar(admin, "u1"), {
    kind: "uploaded",
    path: "u1/avatar/1.jpg",
  });
  assertEquals(filters, [["user_id", "u1"]]);
});

Deno.test("getAvatar treats a missing profile, or one with neither source, as no avatar", async () => {
  assertEquals(await getAvatar(fakeAdmin({ row: null }).admin, "u1"), null);
  for (const avatarPath of [null, "  "]) {
    const { admin } = fakeAdmin({
      row: { user_id: "u1", avatar_path: avatarPath, avatar_preset: null },
    });
    assertEquals(await getAvatar(admin, "u1"), null);
  }
});

Deno.test("SECURITY: getAvatar refuses an avatar_path in another user's folder", async () => {
  const { admin } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u2/avatar/1.jpg", avatar_preset: null },
  });
  assertEquals(await getAvatar(admin, "u1"), null);
});

Deno.test("SECURITY: getAvatar needs the folder separator, not just the prefix", async () => {
  const { admin } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u10/avatar/1.jpg", avatar_preset: null },
  });
  assertEquals(await getAvatar(admin, "u1"), null);
});

Deno.test("getAvatar surfaces a lookup error", async () => {
  const { admin } = fakeAdmin({ row: null, error: { message: "boom" } });
  await assertRejects(() => getAvatar(admin, "u1"), Error, "boom");
});
