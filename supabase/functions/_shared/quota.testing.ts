import type { QuotaPeriod, QuotaSnapshot } from "./quota.ts";
import type { DbClient } from "./supabase.ts";

export const SAMPLE_QUOTA: QuotaSnapshot = {
  tier: "pro",
  period: "month",
  resetsAt: "2026-11-05",
  tryonImage: { used: 12, quota: 250 },
  tryonVideo: { used: 1, quota: 3 },
};

export interface RpcCall {
  fn: string;
  args: Record<string, unknown>;
}

export const SAMPLE_DAILY_QUOTA: QuotaSnapshot = {
  tier: "free",
  period: "day",
  resetsAt: "2026-10-20",
  tryonImage: { used: 10, quota: 10 },
  tryonVideo: { used: 0, quota: 0 },
};

export interface FakeConsumeQuota {
  allowed?: boolean;
  period?: QuotaPeriod;
  windowStart?: string;
  quota?: QuotaSnapshot;
}

export function fakeQuotaAdmin({
  allowed = true,
  period = "month",
  windowStart = "2026-10-19T08:30:12.345+00:00",
  quota = SAMPLE_QUOTA,
}: FakeConsumeQuota = {}): {
  client: DbClient;
  calls: RpcCall[];
} {
  const calls: RpcCall[] = [];
  const client = {
    rpc(fn: string, args: Record<string, unknown>) {
      calls.push({ fn, args });
      if (fn === "consume_quota") {
        return Promise.resolve({
          data: { allowed, windowStart, period, quota: allowed ? null : quota },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as DbClient;
  return { client, calls };
}
