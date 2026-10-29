/**
 * Renders only try-on's own error kind; the shared ones go to
 * `coreErrorResponse` so a validation error cannot answer 400 here and
 * something else elsewhere. Callers keep their own handling for non-core errors
 * and for transport concerns such as CORS.
 */
import { coreErrorResponse, jsonError } from "../http.ts";
import { classifyTryonError } from "./errors.ts";

export function tryonErrorResponse(err: unknown): Response | null {
  const info = classifyTryonError(err);
  if (info === null) return null;

  switch (info.kind) {
    case "generation":
      return jsonError("Image generation failed", "AI_GENERATION_FAILED", 422);
    case "missingAvatar":
      return jsonError("No model photo on file", "NO_AVATAR", 400);
    case "colorUnavailable":
      return jsonError(
        "This colour is no longer available",
        "COLOR_UNAVAILABLE",
        409,
      );
    case "validation":
    case "rateLimit":
    case "quota":
    case "busy":
      return coreErrorResponse(info);
  }
}
