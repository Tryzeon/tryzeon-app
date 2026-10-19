export type BootstrapStep = "liff" | "session" | "profile";

export class BootstrapError extends Error {
  constructor(readonly step: BootstrapStep, readonly reason: unknown) {
    super(`${step}: ${describeError(reason)}`);
    this.name = "BootstrapError";
  }
}

/**
 * The error card is the only place a failure in the LINE webview can be read —
 * it has no devtools to attach — so this keeps whatever identifies the cause:
 * PostgrestError is a plain object, not an Error, and auth/API errors carry
 * their HTTP status outside the message.
 */
export function describeError(err: unknown): string {
  if (typeof err !== "object" || err === null) return String(err);
  const { name, status, code, message } = err as {
    name?: unknown;
    status?: unknown;
    code?: unknown;
    message?: unknown;
  };
  const head = [name, status, code].filter((part) => part !== undefined && part !== "").join(" ");
  return head ? `${head}: ${String(message)}` : String(message);
}
