import { assertEquals } from "@std/assert";
import type { QuotaSnapshot } from "../_shared/quota.ts";
import { taipeiMonthDay, tryonQuotaText } from "./quota-text.ts";

const snapshot = (overrides: Partial<QuotaSnapshot>): QuotaSnapshot => ({
  tier: "pro",
  period: "month",
  resetsAt: "2026-11-04T16:00:00Z",
  tryonImage: { used: 250, quota: 250 },
  tryonVideo: { used: 0, quota: 3 },
  ...overrides,
});

Deno.test("taipeiMonthDay formats the instant in Taipei time", () => {
  assertEquals(taipeiMonthDay("2026-11-04T16:00:00Z"), "11/5");
  assertEquals(taipeiMonthDay("2026-11-04T16:00:00+00:00"), "11/5");
  assertEquals(taipeiMonthDay("2026-11-04T15:59:59Z"), "11/4");
});

Deno.test("free tier is told to come back tomorrow or upgrade", () => {
  assertEquals(
    tryonQuotaText(snapshot({ tier: "free", period: "day" })),
    "今日試穿次數已用完，明天再回來試，或到 App 升級方案拿更多次數。",
  );
});

Deno.test("pro tier gets the reset date and an upgrade hint", () => {
  assertEquals(
    tryonQuotaText(snapshot({ tier: "pro" })),
    "本期試穿次數已用完，11/5 重置。到 App 升級方案可以拿更多次數。",
  );
});

Deno.test("max tier gets the reset date and no upgrade hint", () => {
  assertEquals(
    tryonQuotaText(snapshot({ tier: "max" })),
    "本期試穿次數已用完，11/5 重置。",
  );
});

Deno.test("no snapshot falls back to the bare sentence", () => {
  assertEquals(tryonQuotaText(null), "試穿次數已用完。");
});
