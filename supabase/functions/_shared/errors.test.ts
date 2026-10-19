import { assertEquals } from "@std/assert";
import { classifyCoreError, ServiceBusyError } from "./errors.ts";
import { jsonRateLimited } from "./http.ts";
import { ValidationError } from "./validation.ts";
import { QuotaExceededError } from "./quota.ts";
import { SAMPLE_QUOTA } from "./quota.testing.ts";

Deno.test("classifyCoreError carries the message for validation errors", () => {
  assertEquals(classifyCoreError(new ValidationError("messages must be an array")), {
    kind: "validation",
    message: "messages must be an array",
  });
});

Deno.test("classifyCoreError carries quota for quota errors", () => {
  assertEquals(classifyCoreError(new QuotaExceededError(SAMPLE_QUOTA)), {
    kind: "quota",
    quota: SAMPLE_QUOTA,
  });
});

Deno.test("classifyCoreError narrows a service that refused for capacity", () => {
  assertEquals(classifyCoreError(new ServiceBusyError("image generation is at capacity")), {
    kind: "busy",
  });
});

Deno.test("classifyCoreError returns null for anything else", () => {
  assertEquals(classifyCoreError(new Error("vertex 503")), null);
  assertEquals(classifyCoreError(new TypeError("boom")), null);
  assertEquals(classifyCoreError("not an error"), null);
  assertEquals(classifyCoreError(null), null);
});

Deno.test("coreErrorResponse maps quota to a 429 QUOTA_EXCEEDED carrying the snapshot", async () => {
  const response = coreErrorResponse({ kind: "quota", quota: SAMPLE_QUOTA });
  assertEquals(response.status, 429);
  assertEquals(await response.json(), {
    error: "Quota exceeded",
    code: "QUOTA_EXCEEDED",
    quota: SAMPLE_QUOTA,
  });
});
