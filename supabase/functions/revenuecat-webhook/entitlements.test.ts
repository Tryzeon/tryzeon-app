import { assertEquals } from "@std/assert";
import {
  type ResolvedSubscription,
  resolveSubscription,
  type Subscription,
} from "./entitlements.ts";

const STARTED = Date.parse("2026-08-15T09:30:00Z");
const ENDS = Date.parse("2026-09-15T09:30:00Z");
const ENDS_LATER = Date.parse("2026-10-15T09:30:00Z");
const LAPSED = Date.parse("2026-08-29T00:00:00Z");

const FREE: ResolvedSubscription = {
  tier: "free",
  periodStart: null,
  periodEnd: null,
};

function subscription(
  lookupKeys: string[],
  overrides: Partial<Subscription> = {},
): Subscription {
  return {
    gives_access: true,
    current_period_starts_at: STARTED,
    current_period_ends_at: ENDS,
    entitlements: { items: lookupKeys.map((lookup_key) => ({ lookup_key })) },
    ...overrides,
  };
}

Deno.test("a subscription without access does not cancel one with access", () => {
  const subscriptions = [
    subscription(["max"], { gives_access: false }),
    subscription(["pro"]),
  ];

  assertEquals(resolveSubscription(subscriptions), {
    tier: "pro",
    periodStart: "2026-08-15T09:30:00.000Z",
    periodEnd: "2026-09-15T09:30:00.000Z",
  });
});

Deno.test("the best granted tier wins and carries its own period", () => {
  const subscriptions = [
    subscription(["pro"], { current_period_ends_at: ENDS_LATER }),
    subscription(["max"]),
  ];

  assertEquals(resolveSubscription(subscriptions), {
    tier: "max",
    periodStart: "2026-08-15T09:30:00.000Z",
    periodEnd: "2026-09-15T09:30:00.000Z",
  });
});

Deno.test("a subscription granting several entitlements resolves to the best", () => {
  assertEquals(resolveSubscription([subscription(["pro", "max"])]).tier, "max");
});

Deno.test("the longest-running subscription of the best tier supplies the period", () => {
  const subscriptions = [
    subscription(["pro"]),
    subscription(["pro"], {
      current_period_starts_at: ENDS,
      current_period_ends_at: ENDS_LATER,
    }),
  ];

  assertEquals(resolveSubscription(subscriptions), {
    tier: "pro",
    periodStart: "2026-09-15T09:30:00.000Z",
    periodEnd: "2026-10-15T09:30:00.000Z",
  });
});

Deno.test("access past the period end keeps the lapsed period end", () => {
  const subscriptions = [
    subscription(["pro"], { current_period_ends_at: LAPSED }),
  ];

  assertEquals(resolveSubscription(subscriptions), {
    tier: "pro",
    periodStart: "2026-08-15T09:30:00.000Z",
    periodEnd: "2026-08-29T00:00:00.000Z",
  });
});

Deno.test("a subscription with no period end has no period end", () => {
  const subscriptions = [
    subscription(["max"]),
    subscription(["max"], { current_period_ends_at: null }),
  ];

  assertEquals(resolveSubscription(subscriptions).periodEnd, null);
});

Deno.test("no subscription with access resolves to free with no period", () => {
  const subscriptions = [
    subscription(["pro"], { gives_access: false }),
    subscription(["max"], { gives_access: false }),
  ];

  assertEquals(resolveSubscription(subscriptions), FREE);
});

Deno.test("a customer with no subscriptions resolves to free", () => {
  assertEquals(resolveSubscription([]), FREE);
});

Deno.test("an unknown lookup key is ignored", () => {
  assertEquals(resolveSubscription([subscription(["legacy_unlimited"])]), FREE);
});
