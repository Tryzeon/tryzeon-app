import { generateObject, jsonSchema } from "ai";
import { ServiceBusyError } from "../errors.ts";
import { analysisModel } from "./config.ts";
import { rethrowAsBusy } from "./errors.ts";
import { vertexModel } from "./provider.ts";

/**
 * Raises when the model returns nothing matching `schema`. A caller cannot tell
 * an empty object meaning "nothing found" from one meaning "the model failed",
 * so an unreadable answer is reported rather than flattened into the same shape
 * as a successful one.
 *
 * A missed `deadlineMs` or a capacity refusal raises `ServiceBusyError`.
 */
export async function analyzeFile<
  T extends Record<string, unknown> = Record<string, unknown>,
>(
  { prompt, file, schema, deadlineMs }: {
    prompt: string;
    file: { mediaType: string; data: string };
    schema: Record<string, unknown>;
    deadlineMs: number;
  },
): Promise<T> {
  const deadline = AbortSignal.timeout(deadlineMs);
  try {
    const { object } = await generateObject({
      model: vertexModel(analysisModel()),
      schema: jsonSchema<T>(schema),
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "file", mediaType: file.mediaType, data: file.data },
          ],
        },
      ],
      providerOptions: {
        vertex: { thinkingConfig: { thinkingLevel: "minimal" } },
      },
      abortSignal: deadline,
    });
    return object;
  } catch (err) {
    if (!deadline.aborted) return rethrowAsBusy(err);
    console.warn(`vertex: no analysis within ${deadlineMs}ms`);
    throw new ServiceBusyError("vertex missed the deadline", { cause: err });
  }
}
