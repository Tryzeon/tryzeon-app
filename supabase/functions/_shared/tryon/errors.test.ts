import { assertEquals } from "@std/assert";
import {
  classifyTryonError,
  GenerationFailedError,
  MissingAvatarError,
  ValidationError,
} from "./errors.ts";
import { QuotaExceededError } from "../quota.ts";
import { SAMPLE_QUOTA } from "../quota.testing.ts";

Deno.test("classifyTryonError carries the message for validation errors", () => {
  assertEquals(classifyTryonError(new ValidationError("avatar is required")), {
    kind: "validation",
    message: "avatar is required",
  });
});

Deno.test("classifyTryonError carries quota for quota errors", () => {
  assertEquals(classifyTryonError(new QuotaExceededError(SAMPLE_QUOTA)), {
    kind: "quota",
    quota: SAMPLE_QUOTA,
  });
});

Deno.test("classifyTryonError narrows generation failures", () => {
  assertEquals(classifyTryonError(new GenerationFailedError("null")), {
    kind: "generation",
  });
});

Deno.test("classifyTryonError returns null for foreign errors", () => {
  assertEquals(classifyTryonError(new Error("storage down")), null);
  assertEquals(classifyTryonError(new TypeError("boom")), null);
  assertEquals(classifyTryonError("not an error"), null);
  assertEquals(classifyTryonError(undefined), null);
});

Deno.test("classifyTryonError narrows a missing avatar", () => {
  assertEquals(
    classifyTryonError(new MissingAvatarError("no avatar on profile")),
    {
      kind: "missingAvatar",
    },
  );
});
