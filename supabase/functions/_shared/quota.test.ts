import { assertEquals } from "@std/assert";
import { supabaseUsageCounter } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_DAILY_QUOTA } from "./quota.testing.ts";

Deno.test("supabaseUsageCounter charges consume_quota with the feature", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseUsageCounter(admin.client, "u1", "tryon_image")
    .charge();
  assertEquals(result, { allowed: true });
  assertEquals(admin.calls, [{
    fn: "consume_quota",
    args: { p_user_id: "u1", p_feature: "tryon_image" },
  }]);
});

Deno.test("supabaseUsageCounter reports a rejection with its snapshot, without refunding", async () => {
  const admin = fakeQuotaAdmin({ allowed: false, quota: SAMPLE_DAILY_QUOTA });
  const counter = supabaseUsageCounter(admin.client, "u1", "tryon_image");
  assertEquals(await counter.charge(), {
    allowed: false,
    quota: SAMPLE_DAILY_QUOTA,
  });
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
        p_window_start: "2026-10-19T08:30:12.345+00:00",
      },
    },
  ]);
});

Deno.test("supabaseUsageCounter refund passes the charged daily period and windowStart", async () => {
  const admin = fakeQuotaAdmin({
    period: "day",
    windowStart: "2026-10-17T16:00:00+00:00",
    quota: SAMPLE_DAILY_QUOTA,
  });
  const counter = supabaseUsageCounter(admin.client, "u2", "tryon_image");
  await counter.charge();
  await counter.refund();
  assertEquals(admin.calls[1], {
    fn: "release_quota",
    args: {
      p_user_id: "u2",
      p_feature: "tryon_image",
      p_period: "day",
      p_window_start: "2026-10-17T16:00:00+00:00",
    },
  });
});
