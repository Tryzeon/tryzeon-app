import type { QuotaSnapshot } from "./quota.ts";
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

export function fakeQuotaAdmin(allowed = true): {
  client: DbClient;
  calls: RpcCall[];
} {
  const calls: RpcCall[] = [];
  const client = {
    rpc(fn: string, args: Record<string, unknown>) {
      calls.push({ fn, args });
      if (fn === "consume_quota") {
        return Promise.resolve({
          data: {
            allowed,
            windowStart: "2026-10-19",
            period: "month",
            quota: SAMPLE_QUOTA,
          },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as DbClient;
  return { client, calls };
}
