import type { QuotaSnapshot } from "../_shared/quota.ts";

const taipeiDate = new Intl.DateTimeFormat("en-US", {
  timeZone: "Asia/Taipei",
  month: "numeric",
  day: "numeric",
});

export function taipeiMonthDay(iso: string): string {
  const parts = taipeiDate.formatToParts(new Date(iso));
  const part = (type: "month" | "day") =>
    parts.find((p) => p.type === type)?.value;
  return `${part("month")}/${part("day")}`;
}

export function tryonQuotaText(quota: QuotaSnapshot | null): string {
  if (quota === null) return "試穿次數已用完。";
  if (quota.period === "day") {
    return "今日試穿次數已用完，明天再回來試，或到 App 升級方案拿更多次數。";
  }
  const spent = `本期試穿次數已用完，${taipeiMonthDay(quota.resetsAt)} 重置。`;
  return quota.tier === "max"
    ? spent
    : `${spent}到 App 升級方案可以拿更多次數。`;
}
