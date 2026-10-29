import { FunctionsHttpError } from "@supabase/supabase-js";
import { describe, expect, it } from "vitest";
import {
  ApiError,
  ColorUnavailableError,
  QuotaExceededError,
  type QuotaSnapshot,
  toTryonError,
  tryonFailureMessage,
} from "./errors";

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

describe("toTryonError", () => {
  const httpError = (status: number, body: string) =>
    new FunctionsHttpError(new Response(body, { status }));

  it("turns QUOTA_EXCEEDED into QuotaExceededError carrying the snapshot", async () => {
    const quota = snapshot("pro", "month");
    const err = await toTryonError(
      httpError(429, JSON.stringify({ code: "QUOTA_EXCEEDED", quota })),
    );
    expect(err).toBeInstanceOf(QuotaExceededError);
    expect((err as QuotaExceededError).quota).toEqual(quota);
  });

  it("drops a malformed snapshot", async () => {
    const err = await toTryonError(
      httpError(
        429,
        JSON.stringify({ code: "QUOTA_EXCEEDED", quota: { tier: "gold", period: "month" } }),
      ),
    );
    expect(err).toBeInstanceOf(QuotaExceededError);
    expect((err as QuotaExceededError).quota).toBeNull();
  });

  it.each([
    ["a fair-use rate limit", JSON.stringify({ code: "RATE_LIMIT_EXCEEDED" })],
    ["a 429 without our code", JSON.stringify({ quota: snapshot("pro", "month") })],
    ["an unreadable body", "<html>"],
    ["an empty body", ""],
  ])("keeps %s a neutral rate limit, not a spent quota", async (_, body) => {
    const err = await toTryonError(httpError(429, body));
    expect(err).not.toBeInstanceOf(QuotaExceededError);
    expect(err).toBeInstanceOf(ApiError);
    expect((err as ApiError).status).toBe(429);
    expect(tryonFailureMessage(err)).toBe("操作太頻繁，請稍後再試。");
  });

  it("turns COLOR_UNAVAILABLE into ColorUnavailableError", async () => {
    const err = await toTryonError(httpError(409, JSON.stringify({ code: "COLOR_UNAVAILABLE" })));
    expect(err).toBeInstanceOf(ColorUnavailableError);
    expect(tryonFailureMessage(err)).toBe("店家已移除這個顏色，請重新選擇。");
  });

  it("keeps a 409 without our code an ApiError", async () => {
    const err = await toTryonError(httpError(409, "{}"));
    expect(err).toBeInstanceOf(ApiError);
    expect((err as ApiError).status).toBe(409);
  });

  it("maps other statuses to ApiError", async () => {
    const err = await toTryonError(httpError(422, "{}"));
    expect(err).toBeInstanceOf(ApiError);
    expect((err as ApiError).status).toBe(422);
  });
});
