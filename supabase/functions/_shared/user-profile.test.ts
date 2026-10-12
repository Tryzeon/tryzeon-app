import { assertEquals, assertRejects } from "@std/assert";
import { getAvatarPath } from "./user-profile.ts";
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

Deno.test("getAvatarPath returns a key in the user's own folder", async () => {
  const { admin, filters } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u1/avatar/1.jpg" },
  });
  assertEquals(await getAvatarPath(admin, "u1"), "u1/avatar/1.jpg");
  assertEquals(filters, [["user_id", "u1"]]);
});

Deno.test("getAvatarPath treats a missing profile or empty path as no avatar", async () => {
  assertEquals(await getAvatarPath(fakeAdmin({ row: null }).admin, "u1"), null);
  assertEquals(
    await getAvatarPath(
      fakeAdmin({ row: { user_id: "u1", avatar_path: "  " } }).admin,
      "u1",
    ),
    null,
  );
});

Deno.test("SECURITY: getAvatarPath refuses a profile whose avatar_path sits in another user's folder", async () => {
  // avatar_path is client-written free text, and the LINE adapter reads it on
  // the admin client with no storage policy beneath it. A row of u1's that
  // names u2's object must read as "no avatar", not as u2's photo.
  const { admin } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u2/avatar/1.jpg" },
  });
  assertEquals(await getAvatarPath(admin, "u1"), null);
});

Deno.test("SECURITY: getAvatarPath needs the folder separator, not just the prefix", async () => {
  const { admin } = fakeAdmin({
    row: { user_id: "u1", avatar_path: "u10/avatar/1.jpg" },
  });
  assertEquals(await getAvatarPath(admin, "u1"), null);
});

Deno.test("getAvatarPath surfaces a lookup error", async () => {
  const { admin } = fakeAdmin({ row: null, error: { message: "boom" } });
  await assertRejects(() => getAvatarPath(admin, "u1"), Error, "boom");
});
