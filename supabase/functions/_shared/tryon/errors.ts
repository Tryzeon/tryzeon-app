/**
 * `classifyTryonError` is the one place that maps an unknown error to a typed
 * descriptor, so every adapter (HTTP responses, LINE push messages) renders
 * from the same classification instead of growing its own `instanceof` chain.
 */

import { classifyCoreError, type CoreErrorInfo } from "../errors.ts";

export { ValidationError } from "../validation.ts";

export class GenerationFailedError extends Error {}

export class MissingAvatarError extends Error {}

/**
 * A colour the caller picked that the product no longer has. Never answered by
 * wearing another colour: the shopper saw this one, and a swap would spend a
 * try-on on something they did not choose.
 */
export class ColorUnavailableError extends Error {}

export type TryonErrorInfo =
  | CoreErrorInfo
  | { kind: "generation" }
  | { kind: "missingAvatar" }
  | { kind: "colorUnavailable" };

export function classifyTryonError(err: unknown): TryonErrorInfo | null {
  if (err instanceof GenerationFailedError) {
    return { kind: "generation" };
  }
  if (err instanceof MissingAvatarError) {
    return { kind: "missingAvatar" };
  }
  if (err instanceof ColorUnavailableError) {
    return { kind: "colorUnavailable" };
  }
  return classifyCoreError(err);
}
