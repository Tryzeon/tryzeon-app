import { assertEquals } from "@std/assert";
import { tryonErrorResponse } from "./http.ts";
import { MissingAvatarError } from "./errors.ts";
import { ServiceBusyError } from "../errors.ts";
import { QuotaExceededError } from "../quota.ts";
import { SAMPLE_QUOTA } from "../quota.testing.ts";

Deno.test("tryonErrorResponse renders a missing avatar as 400 NO_AVATAR", async () => {
  const res = tryonErrorResponse(new MissingAvatarError("no avatar on profile"))!;
  assertEquals(res.status, 400);
  assertEquals(await res.json(), {
    error: "No model photo on file",
    code: "NO_AVATAR",
  });
});

Deno.test("tryonErrorResponse renders a busy service as 503 SERVICE_BUSY", async () => {
  const res = tryonErrorResponse(new ServiceBusyError("image generation is at capacity"))!;
  assertEquals(res.status, 503);
  assertEquals(await res.json(), {
    error: "Service is busy, please try again shortly",
    code: "SERVICE_BUSY",
  });
});

Deno.test("tryonErrorResponse renders a spent quota as 429 QUOTA_EXCEEDED with the snapshot", async () => {
  const res = tryonErrorResponse(new QuotaExceededError(SAMPLE_QUOTA))!;
  assertEquals(res.status, 429);
  assertEquals(await res.json(), {
    error: "Quota exceeded",
    code: "QUOTA_EXCEEDED",
    quota: SAMPLE_QUOTA,
  });
});
