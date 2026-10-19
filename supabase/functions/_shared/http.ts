import { CORE_ERROR_CODE, type CoreErrorInfo } from "./errors.ts";
import type { QuotaSnapshot } from "./quota.ts";

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

export function jsonError(
  message: string,
  code: string,
  status: number,
): Response {
  return json({ error: message, code }, status);
}

/** For responses that depend on who is asking, or that record a side effect when served. */
export function noStore(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Cache-Control", "no-store");
  return new Response(response.body, { status: response.status, headers });
}

export function jsonRateLimited(): Response {
  return jsonError("Rate limit exceeded", CORE_ERROR_CODE.rateLimit, 429);
}

export function jsonQuotaExceeded(quota: QuotaSnapshot | null): Response {
  return json(
    { error: "Quota exceeded", code: CORE_ERROR_CODE.quota, quota },
    429,
  );
}

export function coreErrorResponse(info: CoreErrorInfo): Response {
  switch (info.kind) {
    case "validation":
      return jsonError(info.message, CORE_ERROR_CODE.validation, 400);
    case "rateLimit":
      return jsonRateLimited();
    case "quota":
      return jsonQuotaExceeded(info.quota);
    case "busy":
      return jsonError(
        "Service is busy, please try again shortly",
        CORE_ERROR_CODE.busy,
        503,
      );
  }
}
