import { generateObject, jsonSchema } from "ai";
import { vertexModel } from "./vertex/provider.ts";
import { analysisModel } from "./vertex/config.ts";
import { rethrowAsBusy } from "./vertex/errors.ts";
import { ServiceBusyError } from "./errors.ts";
import { detectMimeType } from "./image-utils.ts";
import { jsonError, jsonRateLimited } from "./http.ts";
import { checkWindowedRateLimit, type WindowedLimit } from "./rate-limit.ts";

export const MAX_BASE64_LENGTH = 8 * 1024 * 1024;

type ValidationResult =
  | { ok: true; value: string }
  | { ok: false; response: Response };

export function validateBase64(base64: unknown): ValidationResult {
  if (typeof base64 !== "string" || base64.length < 16) {
    return { ok: false, response: jsonError("Missing or invalid base64", "BAD_REQUEST", 400) };
  }
  if (base64.length > MAX_BASE64_LENGTH) {
    return { ok: false, response: jsonError("Image payload too large", "PAYLOAD_TOO_LARGE", 413) };
  }
  return { ok: true, value: base64 };
}

export const IMAGE_ANALYSIS_RATE_LIMIT: WindowedLimit = { perMinute: 15, perDay: 200 };

export async function checkImageAnalysisRateLimit(
  userId: string,
  bucketPrefix: string,
): Promise<Response | null> {
  const allowed = await checkWindowedRateLimit(
    userId,
    bucketPrefix,
    IMAGE_ANALYSIS_RATE_LIMIT,
  );
  return allowed ? null : jsonRateLimited();
}

// The app gives up at 20 s (`ProductImageAnalyzerImpl`, `LabelTaggerImpl`);
// this leaves room for its upload and the function's own reads, so a stall is
// answered as busy instead of surfacing as a client timeout.
const ANALYSIS_DEADLINE_MS = 15_000;

/**
 * Raises when the model returns nothing matching `schema`. A caller cannot tell
 * an empty object meaning "no attributes found" from one meaning "the model
 * failed", so an unreadable answer is reported rather than flattened into the
 * same shape as a successful one.
 *
 * A missed deadline or a capacity refusal raises `ServiceBusyError`.
 */
export async function analyzeImage<T extends Record<string, unknown> = Record<string, unknown>>(
  { base64, prompt, schema }: {
    base64: string;
    prompt: string;
    schema: Record<string, unknown>;
  },
): Promise<T> {
  const deadline = AbortSignal.timeout(ANALYSIS_DEADLINE_MS);
  try {
    const { object } = await generateObject({
      model: vertexModel(analysisModel()),
      schema: jsonSchema<T>(schema),
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "file", mediaType: detectMimeType(base64), data: base64 },
          ],
        },
      ],
      providerOptions: { vertex: { thinkingConfig: { thinkingLevel: "minimal" } } },
      abortSignal: deadline,
    });
    return object;
  } catch (err) {
    if (!deadline.aborted) return rethrowAsBusy(err);
    console.warn(`vertex: no image analysis within ${ANALYSIS_DEADLINE_MS}ms`);
    throw new ServiceBusyError("vertex missed the deadline", { cause: err });
  }
}
