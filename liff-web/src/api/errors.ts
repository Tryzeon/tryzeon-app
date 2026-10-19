import { FunctionsHttpError } from "@supabase/supabase-js";

export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "ApiError";
  }
}

/**
 * supabase-js wraps every non-2xx in a FunctionsHttpError whose message is
 * always "Edge Function returned a non-2xx status code" — a used-up quota and a
 * failed generation look identical. Telling them apart means reading the status,
 * which sits on the `context` Response and can be read synchronously.
 *
 * Takes the status only, not the `code` in the body: reading the body is async,
 * and every failure that currently needs its own wording (429 quota, 422
 * generation failure) is already distinguishable by status alone.
 */
export function toApiError(error: unknown): Error {
  if (!(error instanceof FunctionsHttpError)) {
    return error instanceof Error ? error : new Error(String(error));
  }
  const resp = error.context as Response;
  return new ApiError("request failed", resp.status);
}

export interface QuotaSnapshot {
  tier: "free" | "pro" | "max";
  period: "day" | "month";
  resetsAt: string;
  tryonImage: { used: number; quota: number };
  tryonVideo: { used: number; quota: number };
}

export class QuotaExceededError extends Error {
  constructor(readonly quota: QuotaSnapshot | null) {
    super("quota exhausted");
    this.name = "QuotaExceededError";
  }
}

const taipeiDate = new Intl.DateTimeFormat("en-US", {
  timeZone: "Asia/Taipei",
  month: "numeric",
  day: "numeric",
});

function taipeiMonthDay(iso: string): string {
  const parts = taipeiDate.formatToParts(new Date(iso));
  const part = (type: "month" | "day") => parts.find((p) => p.type === type)?.value;
  return `${part("month")}/${part("day")}`;
}

function quotaExceededMessage(quota: QuotaSnapshot | null): string {
  if (quota === null) return "試穿次數已用完。";
  if (quota.period === "day") {
    return "今日試穿次數已用完，明天再回來試，或到 App 升級方案拿更多次數。";
  }
  const spent = `本期試穿次數已用完，${taipeiMonthDay(quota.resetsAt)} 重置。`;
  return quota.tier === "max" ? spent : `${spent}到 App 升級方案可以拿更多次數。`;
}

const TIERS = ["free", "pro", "max"];
const PERIODS = ["day", "month"];

const isCounter = (v: unknown): v is { used: number; quota: number } =>
  typeof v === "object" && v !== null &&
  typeof (v as { used?: unknown }).used === "number" &&
  typeof (v as { quota?: unknown }).quota === "number";

export function parseQuotaSnapshot(value: unknown): QuotaSnapshot | null {
  if (typeof value !== "object" || value === null) return null;
  const q = value as Record<string, unknown>;
  if (
    !TIERS.includes(q.tier as string) ||
    !PERIODS.includes(q.period as string) ||
    typeof q.resetsAt !== "string" ||
    Number.isNaN(Date.parse(q.resetsAt)) ||
    !isCounter(q.tryonImage) ||
    !isCounter(q.tryonVideo)
  ) {
    return null;
  }
  return q as unknown as QuotaSnapshot;
}

export function tryonFailureMessage(err: unknown): string {
  if (err instanceof QuotaExceededError) return quotaExceededMessage(err.quota);
  if (err instanceof ApiError) {
    if (err.status === 422) return "這張照片沒能生成，請稍後再試。";
    if (err.status === 429) return "操作太頻繁，請稍後再試。";
  }
  return "出了點狀況，請稍後再試。";
}
