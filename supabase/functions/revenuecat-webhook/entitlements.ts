export interface Subscription {
  /** RevenueCat's verdict, already covering trials, grace periods and pauses. */
  gives_access: boolean;
  current_period_starts_at: number;
  current_period_ends_at: number | null;
  entitlements: { items: { lookup_key: string }[] };
}

/**
 * Entitlement lookup keys in RevenueCat, which are also the
 * `subscription_tiers.id` values — the two are deliberately the same string so
 * no mapping table is needed. Mirrors `AppConstants.entitlement*Id` on the
 * client.
 */
export const SUBSCRIPTION_TIER = {
  free: "free",
  pro: "pro",
  max: "max",
} as const;

export type SubscriptionTier =
  typeof SUBSCRIPTION_TIER[keyof typeof SUBSCRIPTION_TIER];

/** Best first. */
const TIER_PRECEDENCE: readonly SubscriptionTier[] = [
  SUBSCRIPTION_TIER.max,
  SUBSCRIPTION_TIER.pro,
];

export interface ResolvedSubscription {
  tier: SubscriptionTier;
  periodStart: string | null;
  periodEnd: string | null;
}

const FREE_SUBSCRIPTION: ResolvedSubscription = {
  tier: SUBSCRIPTION_TIER.free,
  periodStart: null,
  periodEnd: null,
};

function grants(subscription: Subscription, tier: SubscriptionTier): boolean {
  return subscription.entitlements.items.some((entitlement) =>
    entitlement.lookup_key === tier
  );
}

function periodEndMs(subscription: Subscription): number {
  return subscription.current_period_ends_at ?? Infinity;
}

function toIso(ms: number | null): string | null {
  return ms === null ? null : new Date(ms).toISOString();
}

/**
 * The customer's whole subscription set decides the tier, never a single
 * event. RevenueCat does not guarantee webhook ordering, and one subscription
 * expiring says nothing about the others — a sandbox subscription lapsing while
 * a promotional grant is active must not drop the customer to free. When
 * several subscriptions grant the best tier, the one running longest supplies
 * the period, as that is when access actually ends.
 */
export function resolveSubscription(
  subscriptions: readonly Subscription[],
): ResolvedSubscription {
  const granting = subscriptions.filter((subscription) =>
    subscription.gives_access
  );

  for (const tier of TIER_PRECEDENCE) {
    const longest = granting
      .filter((subscription) => grants(subscription, tier))
      .reduce<Subscription | undefined>(
        (best, subscription) =>
          !best || periodEndMs(subscription) > periodEndMs(best)
            ? subscription
            : best,
        undefined,
      );

    if (longest) {
      return {
        tier,
        periodStart: toIso(longest.current_period_starts_at),
        periodEnd: toIso(longest.current_period_ends_at),
      };
    }
  }

  return FREE_SUBSCRIPTION;
}
