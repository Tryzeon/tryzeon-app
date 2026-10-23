import { assertEquals, assertRejects } from "@std/assert";
import type { Subscription } from "./entitlements.ts";
import {
  fetchCustomerSubscriptions,
  RevenueCatApiError,
} from "./revenuecat-api.ts";

const PROJECT = { projectId: "proj1ab2c3d4", apiKey: "sk_test" };
const APP_USER_ID = "19b8de26-77c1-49f1-aa18-019a391603e2";

function subscription(lookupKey: string): Subscription {
  return {
    gives_access: true,
    current_period_starts_at: 0,
    current_period_ends_at: null,
    entitlements: { items: [{ lookup_key: lookupKey }] },
  };
}

function stubFetch(
  respond: (url: string) => Response,
): { requests: Request[]; restore: () => void } {
  const requests: Request[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const request = new Request(input, init);
    requests.push(request);
    return Promise.resolve(respond(request.url));
  }) as typeof fetch;
  return { requests, restore: () => globalThis.fetch = original };
}

Deno.test("every page of the customer's subscriptions is read", async () => {
  const nextPage =
    `/v2/projects/${PROJECT.projectId}/customers/${APP_USER_ID}/subscriptions?starting_after=sub1`;
  const { requests, restore } = stubFetch((url) =>
    url.includes("starting_after")
      ? Response.json({ items: [subscription("max")], next_page: null })
      : Response.json({ items: [subscription("pro")], next_page: nextPage })
  );

  try {
    const subscriptions = await fetchCustomerSubscriptions(
      PROJECT,
      APP_USER_ID,
    );

    assertEquals(subscriptions, [subscription("pro"), subscription("max")]);
    assertEquals(
      requests.map((request) => request.url),
      [
        `https://api.revenuecat.com/v2/projects/${PROJECT.projectId}/customers/${APP_USER_ID}/subscriptions?limit=100`,
        `https://api.revenuecat.com${nextPage}`,
      ],
    );
    assertEquals(
      requests[0].headers.get("Authorization"),
      `Bearer ${PROJECT.apiKey}`,
    );
  } finally {
    restore();
  }
});

Deno.test("a failed request throws so the webhook is retried", async () => {
  const { restore } = stubFetch(() =>
    Response.json({ type: "rate_limit_error" }, { status: 429 })
  );

  try {
    await assertRejects(
      () => fetchCustomerSubscriptions(PROJECT, APP_USER_ID),
      RevenueCatApiError,
    );
  } finally {
    restore();
  }
});
