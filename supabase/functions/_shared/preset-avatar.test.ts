import { assertEquals } from "@std/assert";
import { presetAvatarKey } from "./preset-avatar.ts";
import { Constants } from "./database.types.ts";

Deno.test("presetAvatarKey derives every preset's R2 key from its id", () => {
  assertEquals(
    Constants.public.Enums.preset_avatar.map((id) => presetAvatarKey(id)),
    ["presets/female.jpg", "presets/male.jpg"],
  );
});
