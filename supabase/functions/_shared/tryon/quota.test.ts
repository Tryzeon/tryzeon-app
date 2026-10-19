import { assertEquals } from "@std/assert";
import { supabaseQuota } from "./quota.ts";
import { fakeQuotaAdmin } from "../quota.testing.ts";

Deno.test("supabaseQuota charges the image feature for image mode", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseQuota(admin.client)("u1", "image").charge();
  assertEquals(result, { allowed: true });
  assertEquals(admin.calls, [{
    fn: "consume_quota",
    args: { p_user_id: "u1", p_feature: "tryon_image" },
  }]);
});

Deno.test("supabaseQuota charges the video feature for video mode", async () => {
  const admin = fakeQuotaAdmin();
  await supabaseQuota(admin.client)("u1", "video").charge();
  assertEquals(admin.calls[0].args.p_feature, "tryon_video");
});
