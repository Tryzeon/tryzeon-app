import type { Enums } from "./database.types.ts";
import { asJsonObject, type DbClient } from "./supabase.ts";

export type UsageFeature = Enums<"usage_feature">;
export type QuotaPeriod = Enums<"quota_period">;

export interface FeatureQuota {
  used: number;
  quota: number;
}

export interface QuotaSnapshot {
  tier: "free" | "pro" | "max";
  period: QuotaPeriod;
  resetsAt: string;
  tryonImage: FeatureQuota;
  tryonVideo: FeatureQuota;
}

export class QuotaExceededError extends Error {
  constructor(public readonly quota: QuotaSnapshot | null) {
    super("quota exceeded");
  }
}

export type ChargeResult =
  | { allowed: true }
  | { allowed: false; quota: QuotaSnapshot | null };

/**
 * The usage counter one unit of work is charged against. `charge` runs before
 * any work; `refund` compensates when that work then fails, and is a no-op if
 * the charge never landed.
 */
export interface UsageCounter {
  charge(): Promise<ChargeResult>;
  refund(): Promise<void>;
}

interface ConsumeQuotaResult {
  allowed: boolean;
  windowStart: string;
  period: QuotaPeriod;
  quota: QuotaSnapshot | null;
}

export function supabaseUsageCounter(
  adminClient: DbClient,
  userId: string,
  feature: UsageFeature,
): UsageCounter {
  let charged: { windowStart: string; period: QuotaPeriod } | null = null;

  return {
    async charge() {
      const { data, error } = await adminClient.rpc("consume_quota", {
        p_user_id: userId,
        p_feature: feature,
      });
      if (error) {
        throw new Error(`Failed to consume quota: ${error.message}`);
      }
      const result = asJsonObject<ConsumeQuotaResult>(data);
      if (!result?.allowed) {
        charged = null;
        return { allowed: false, quota: result?.quota ?? null };
      }
      charged = { windowStart: result.windowStart, period: result.period };
      return { allowed: true };
    },

    async refund() {
      if (!charged) return;
      const { windowStart, period } = charged;
      // Cleared before the call, not after: a refund that throws must not leave
      // the port willing to issue a second one.
      charged = null;
      const { error } = await adminClient.rpc("release_quota", {
        p_user_id: userId,
        p_feature: feature,
        p_period: period,
        p_window_start: windowStart,
      });
      if (error) {
        console.error("Quota rollback failed:", { userId, feature, error });
      }
    },
  };
}
