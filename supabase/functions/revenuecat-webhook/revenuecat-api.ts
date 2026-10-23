import type { Subscription } from "./entitlements.ts";

const API_ORIGIN = "https://api.revenuecat.com";
const PAGE_SIZE = 100;

export class RevenueCatApiError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
    this.name = "RevenueCatApiError";
  }
}

export interface RevenueCatProject {
  projectId: string;
  /** A v2 secret key with `customer_information:subscriptions:read`. */
  apiKey: string;
}

interface SubscriptionPage {
  items: Subscription[];
  next_page: string | null;
}

/**
 * The customer's current state, which is the only thing the webhook trusts.
 * Leaving out the `environment` filter returns sandbox and production
 * subscriptions together, so a TestFlight tester and a paying user resolve
 * through the same path. Promotional grants are subscriptions too.
 */
export async function fetchCustomerSubscriptions(
  project: RevenueCatProject,
  appUserId: string,
): Promise<Subscription[]> {
  const subscriptions: Subscription[] = [];
  let url: string | null = `${API_ORIGIN}/v2/projects/${
    encodeURIComponent(project.projectId)
  }/customers/${
    encodeURIComponent(appUserId)
  }/subscriptions?limit=${PAGE_SIZE}`;

  while (url) {
    const response: Response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${project.apiKey}`,
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      throw new RevenueCatApiError(
        response.status,
        `RevenueCat subscriptions fetch failed (${response.status}): ${await response
          .text()}`,
      );
    }

    const page = await response.json() as SubscriptionPage;
    subscriptions.push(...page.items);
    url = page.next_page ? new URL(page.next_page, API_ORIGIN).href : null;
  }

  return subscriptions;
}
