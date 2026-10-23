import { assertEquals } from "@std/assert";
import {
  type ResolvedSubscription,
  resolveSubscription,
  type Subscriber,
} from "./entitlements.ts";

const NOW = new Date("2026-08-30T00:00:00Z");
const PURCHASED = "2026-08-15T09:30:00Z";
const FUTURE = "2026-09-15T09:30:00Z";
const PAST = "2026-08-29T00:00:00Z";

const FREE: ResolvedSubscription = {
  tier: "free",
  periodStart: null,
  periodEnd: null,
};

Deno.test("a lapsed entitlement does not cancel an active one", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: { purchase_date: "2026-07-29T00:00:00Z", expires_date: PAST },
      max: { purchase_date: PURCHASED, expires_date: null },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), {
    tier: "max",
    periodStart: PURCHASED,
    periodEnd: null,
  });
});

Deno.test("the best held entitlement wins and carries its own period", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: {
        purchase_date: "2026-08-01T00:00:00Z",
        expires_date: "2026-09-01T00:00:00Z",
      },
      max: { purchase_date: PURCHASED, expires_date: FUTURE },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), {
    tier: "max",
    periodStart: PURCHASED,
    periodEnd: FUTURE,
  });
});

Deno.test("a grace period still counts as access and keeps the lapsed period end", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: {
        purchase_date: "2026-07-29T00:00:00Z",
        expires_date: PAST,
        grace_period_expires_date: FUTURE,
      },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), {
    tier: "pro",
    periodStart: "2026-07-29T00:00:00Z",
    periodEnd: PAST,
  });
});

Deno.test("an entitlement with no expiry has no period end", () => {
  const subscriber: Subscriber = {
    entitlements: { pro: { purchase_date: PURCHASED } },
  };

  assertEquals(resolveSubscription(subscriber, NOW), {
    tier: "pro",
    periodStart: PURCHASED,
    periodEnd: null,
  });
});

Deno.test("every entitlement expired resolves to free with no period", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: { purchase_date: "2026-07-29T00:00:00Z", expires_date: PAST },
      max: { purchase_date: "2026-07-29T00:00:00Z", expires_date: PAST },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), FREE);
});

Deno.test("a customer with no entitlements resolves to free", () => {
  assertEquals(resolveSubscription({}, NOW), FREE);
});

Deno.test("an unknown entitlement id is ignored", () => {
  const subscriber: Subscriber = {
    entitlements: {
      legacy_unlimited: { purchase_date: PURCHASED, expires_date: FUTURE },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), FREE);
});

Deno.test("an unparseable expiry is not treated as access", () => {
  const subscriber: Subscriber = {
    entitlements: {
      max: { purchase_date: PURCHASED, expires_date: "not a date" },
    },
  };

  assertEquals(resolveSubscription(subscriber, NOW), FREE);
});
