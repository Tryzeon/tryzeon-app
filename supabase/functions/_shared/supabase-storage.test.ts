import { assertEquals } from "@std/assert";
import { ownsUserObjectPath } from "./supabase-storage.ts";

Deno.test("ownsUserObjectPath accepts a key in the user's own folder", () => {
  assertEquals(ownsUserObjectPath("u1", "u1/top/a.png"), true);
});

Deno.test("SECURITY: ownsUserObjectPath refuses a key in another user's folder", () => {
  assertEquals(ownsUserObjectPath("u1", "u2/top/a.png"), false);
});

Deno.test("ownsUserObjectPath needs the folder separator, not just the prefix", () => {
  assertEquals(ownsUserObjectPath("u1", "u10/top/a.png"), false);
  assertEquals(ownsUserObjectPath("u1", "u1"), false);
});

Deno.test("ownsUserObjectPath refuses an empty or non-string key", () => {
  assertEquals(ownsUserObjectPath("u1", ""), false);
  assertEquals(ownsUserObjectPath("u1", null), false);
  assertEquals(ownsUserObjectPath("u1", undefined), false);
});
