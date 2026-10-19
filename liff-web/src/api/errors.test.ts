import { describe, expect, it } from "vitest";
import { ApiError, QuotaExhaustedError, type QuotaSnapshot, tryonFailureMessage } from "./errors";

const snapshot = (tier: QuotaSnapshot["tier"], period: QuotaSnapshot["period"]): QuotaSnapshot => ({
  tier,
  period,
  resetsAt: "2026-11-04T16:00:00+00:00",
  tryonImage: { used: 1, quota: 1 },
  tryonVideo: { used: 0, quota: 0 },
});

describe("tryonFailureMessage", () => {
  it("tells a free user to come back tomorrow", () => {
    expect(tryonFailureMessage(new QuotaExceededError(snapshot("free", "day")))).toBe(
      "今日試穿次數已用完，明天再回來試，或到 App 升級方案拿更多次數。",
    );
  });

  it("gives a pro user the reset date in Taipei time and an upgrade hint", () => {
    expect(tryonFailureMessage(new QuotaExceededError(snapshot("pro", "month")))).toBe(
      "本期試穿次數已用完，11/5 重置。到 App 升級方案可以拿更多次數。",
    );
  });

  it("omits the upgrade hint for max", () => {
    expect(tryonFailureMessage(new QuotaExceededError(snapshot("max", "month")))).toBe(
      "本期試穿次數已用完，11/5 重置。",
    );
  });

  it("falls back when there is no snapshot", () => {
    expect(tryonFailureMessage(new QuotaExceededError(null))).toBe("試穿次數已用完。");
  });

  it("keeps the other messages", () => {
    expect(tryonFailureMessage(new ApiError("x", 422))).toBe("這張照片沒能生成，請稍後再試。");
    expect(tryonFailureMessage(new ApiError("x", 429))).toBe("操作太頻繁，請稍後再試。");
    expect(tryonFailureMessage(new Error("boom"))).toBe("出了點狀況，請稍後再試。");
  });
});
