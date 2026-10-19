/**
 * There is deliberately no "the model failed" kind. Whether an unusable model
 * result is an error at all is the feature's call: try-on raises one, chat
 * degrades to fallback text. That makes it a feature arm, never a shared one.
 */
import { QuotaExceededError, type QuotaSnapshot } from "./quota.ts";
import { ValidationError } from "./validation.ts";

export class ServiceBusyError extends Error {}

export type CoreErrorInfo =
  | { kind: "validation"; message: string }
  | { kind: "quota"; quota: QuotaSnapshot | null }
  | { kind: "busy" };

export const CORE_ERROR_CODE: Record<CoreErrorInfo["kind"], string> = {
  validation: "VALIDATION_ERROR",
  quota: "QUOTA_EXCEEDED",
  busy: "SERVICE_BUSY",
};

export function classifyCoreError(err: unknown): CoreErrorInfo | null {
  if (err instanceof ValidationError) {
    return { kind: "validation", message: err.message };
  }
  if (err instanceof QuotaExceededError) {
    return { kind: "quota", quota: err.quota };
  }
  if (err instanceof ServiceBusyError) {
    return { kind: "busy" };
  }
  return null;
}
