import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export type FeatureName = "chat" | "tryon" | "tryon_video";

/**
 * Increments the feature usage count for a user.
 * Returns true if the increment was successful (within quota limits).
 * Returns false if the user has exceeded their quota.
 */
export async function incrementFeatureUsage(
  adminClient: SupabaseClient,
  userId: string,
  featureName: FeatureName
): Promise<{ success: boolean; error?: any }> {
  const { data: isAllowed, error } = await adminClient.rpc(
    "increment_feature_usage",
    { p_user_id: userId, p_feature_name: featureName }
  );

  if (error) {
    return { success: false, error };
  }

  return { success: isAllowed };
}

/**
 * Decrements the feature usage count for a user (rollback operation).
 * Used to compensate for failed operations after quota was already incremented.
 * Returns true if the decrement was successful.
 * Returns false if there was nothing to rollback (count was already 0).
 */
export async function rollbackFeatureUsage(
  adminClient: SupabaseClient,
  userId: string,
  featureName: FeatureName
): Promise<{ success: boolean; error?: any }> {
  const { data: wasRolledBack, error } = await adminClient.rpc(
    "decrement_feature_usage",
    { p_user_id: userId, p_feature_name: featureName }
  );

  if (error) {
    return { success: false, error };
  }

  return { success: wasRolledBack };
}

/**
 * Quota manager class that tracks quota state and provides automatic rollback.
 * Usage:
 * 
 * const quotaManager = new QuotaManager(adminClient, userId, featureName);
 * const canProceed = await quotaManager.incrementQuota();
 * if (!canProceed) return rateLimitResponse;
 * 
 * try {
 *   // ... do work that might fail
 * } catch (err) {
 *   await quotaManager.rollbackQuota();
 *   throw err;
 * }
 */
export class QuotaManager {
  private quotaIncremented = false;

  constructor(
    private adminClient: SupabaseClient,
    private userId: string,
    private featureName: FeatureName
  ) {}

  /**
   * Increments quota and marks it as incremented for potential rollback.
   * Returns true if quota increment was successful (user within limits).
   * Returns false if user has exceeded quota limits.
   */
  async incrementQuota(): Promise<boolean> {
    const { success, error } = await incrementFeatureUsage(
      this.adminClient,
      this.userId,
      this.featureName
    );

    if (error) {
      throw new Error(`Failed to increment quota: ${error.message}`);
    }

    if (success) {
      this.quotaIncremented = true;
    }

    return success;
  }

  /**
   * Rolls back quota if it was previously incremented.
   * Safe to call multiple times - will only rollback once.
   * Logs errors but does not throw to avoid masking original errors.
   */
  async rollbackQuota(): Promise<void> {
    if (!this.quotaIncremented) {
      return; // Nothing to rollback
    }

    const { success, error } = await rollbackFeatureUsage(
      this.adminClient,
      this.userId,
      this.featureName
    );

    if (error) {
      console.error("Quota rollback failed:", {
        userId: this.userId,
        featureName: this.featureName,
        error
      });
    }

    this.quotaIncremented = false;
  }

  /**
   * Returns whether quota was incremented and might need rollback.
   */
  get isQuotaIncremented(): boolean {
    return this.quotaIncremented;
  }
}