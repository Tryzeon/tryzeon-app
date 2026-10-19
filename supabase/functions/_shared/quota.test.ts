import { assertEquals } from "@std/assert";
import { supabaseUsageCounter } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_QUOTA } from "./quota.testing.ts";

Deno.test("supabaseUsageCounter charges consume_quota with the feature", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseUsageCounter(admin.client, "u1", "tryon_image").charge();
  assertEquals(result, { allowed: true });
  assertEquals(admin.calls, [{
    fn: "consume_quota",
    args: { p_user_id: "u1", p_feature: "tryon_image" },
  }]);
});

Deno.test("supabaseUsageCounter reports a rejection without refunding", async () => {
  const admin = fakeQuotaAdmin(false);
  const counter = supabaseUsageCounter(admin.client, "u1", "tryon_image");
  assertEquals((await counter.charge()).allowed, false);
  await counter.refund();
  assertEquals(admin.calls.map((c) => c.fn), ["consume_quota"]);
});

Deno.test("supabaseUsageCounter refund passes the charged windowStart, only once", async () => {
  const admin = fakeQuotaAdmin();
  const counter = supabaseUsageCounter(admin.client, "u1", "tryon_video");
  await counter.charge();
  await counter.refund();
  await counter.refund();
  assertEquals(admin.calls, [
    {
      fn: "consume_quota",
      args: { p_user_id: "u1", p_feature: "tryon_video" },
    },
    {
      fn: "release_quota",
      args: {
        p_user_id: "u1",
        p_feature: "tryon_video",
        p_period: "month",
        p_window_start: "2026-10-19",
      },
    },
  ]);
});
