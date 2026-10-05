/**
 * Owns what is provider-specific; builds no prompts (see `prompt.ts`) and
 * persists nothing.
 */
import { decodeBase64 } from "@std/encoding/base64";
import { experimental_generateVideo, generateText } from "ai";
import { detectMimeType } from "../image-utils.ts";
import {
  tryonExperimentalImageModel,
  tryonExperimentalVideoModel,
  tryonImageModel,
  tryonVideoModel,
} from "../vertex/config.ts";
import { ServiceBusyError } from "../errors.ts";
import { rethrowAsBusy } from "../vertex/errors.ts";
import { QUOTA_WINDOW_RETRIES } from "../vertex/retry.ts";
import { GenerationFailedError } from "./errors.ts";
import {
  vertexInteractionsModel,
  vertexModel,
  vertexVideoModel,
} from "../vertex/provider.ts";
import {
  buildTaskPrompt,
  buildVideoPrompt,
  SYSTEM_INSTRUCTION,
} from "./prompt.ts";
import type { ImageGenerationOptions, VideoGenerationOptions } from "./types.ts";

/**
 * An `image` part rather than a `file` one so the SDK settles the media type: a
 * `file` part is taken at its word, and declaring the type wrong is a
 * documented way to make Gemini return no image at all.
 */
function imagePart(base64: string) {
  return { type: "image" as const, image: base64 };
}

// Healthy flash answers in 9–17 s; 45 s cuts a stall while leaving pro
// (20–28 s) most of the deadline.
const PRIMARY_ATTEMPT_TIMEOUT_MS = 45_000;

// Under the platform's 150 s kill, which skips the quota refund, with room for
// loading sources and the R2 upload around generation.
const GENERATION_DEADLINE_MS = 135_000;

export async function generateTryonImage(
  avatarImage: string,
  garmentGroups: string[][],
  opts: ImageGenerationOptions = {},
): Promise<string | null> {
  const taskPrompt = buildTaskPrompt(garmentGroups, opts);
  console.log("[tryon] task prompt:\n" + taskPrompt);

  const images = [avatarImage, ...garmentGroups.flat()];
  const generate = (
    modelId: string,
    maxRetries: number,
    abortSignal: AbortSignal,
  ) => generateWithModel(modelId, taskPrompt, images, maxRetries, abortSignal);

  // Our own signal, not the SDK's `timeout`: the SDK aborts a retry backoff with
  // a plain `AbortError`, so only the signal can tell the deadline fired.
  const deadline = AbortSignal.timeout(GENERATION_DEADLINE_MS);
  try {
    if (opts.engine !== "experimental") {
      const primaryModel = tryonImageModel();
      const attempt = AbortSignal.timeout(PRIMARY_ATTEMPT_TIMEOUT_MS);
      try {
        const image = await generate(
          primaryModel,
          0,
          AbortSignal.any([deadline, attempt]),
        );
        if (image) return image;
      } catch (err) {
        if (deadline.aborted) throw err;
        console.warn(
          attempt.aborted
            ? `vertex: model=${primaryModel} timed out after ${PRIMARY_ATTEMPT_TIMEOUT_MS}ms`
            : `vertex: model=${primaryModel} failed: ${err}`,
        );
      }
    }
    return await generate(
      tryonExperimentalImageModel(),
      QUOTA_WINDOW_RETRIES,
      deadline,
    );
  } catch (err) {
    if (!deadline.aborted) return rethrowAsBusy(err);
    console.warn(`vertex: no answer within ${GENERATION_DEADLINE_MS}ms`);
    throw new ServiceBusyError("vertex missed the deadline", { cause: err });
  }
}

/**
 * `responseModalities` and `imageConfig` are Gemini's own settings, so they
 * travel under `providerOptions.vertex` rather than as call options.
 */
async function generateWithModel(
  modelId: string,
  taskPrompt: string,
  images: string[],
  maxRetries: number,
  abortSignal: AbortSignal,
): Promise<string | null> {
  const { files, finishReason } = await generateText({
    model: vertexModel(modelId),
    system: SYSTEM_INSTRUCTION,
    messages: [{
      role: "user",
      content: [
        {
          type: "text",
          text: taskPrompt,
        },
        ...images.map(imagePart),
      ],
    }],
    providerOptions: {
      vertex: {
        responseModalities: ["IMAGE"],
        imageConfig: {
          aspectRatio: "9:16",
          imageSize: "2K",
          imageOutputOptions: {
            mimeType: "image/jpeg",
            compressionQuality: 95,
          },
        },
      },
    },
    maxRetries,
    abortSignal,
  });

  const image = files.find((file) => file.mediaType.startsWith("image/"));
  if (!image) {
    console.error(
      `No image in Vertex response, model=${modelId} finishReason:`,
      finishReason,
    );
    return null;
  }
  return image.base64;
}

/**
 * One synchronous Interactions call with the video inline in the response. A
 * `file` part rather than `image` here: the Interactions API drops inline data
 * without a concrete media type, so it is sniffed from the bytes.
 *
 * The video is decoded from `base64`, never read through `uint8Array`: the
 * SDK's getter decodes via `Uint8Array.from(string)`, which peaks at dozens of
 * bytes of heap per video byte and runs a multi-megabyte clip past the edge
 * function's memory limit.
 */
async function generateInteractionsVideo(
  tryonImageBase64: string,
  opts: VideoGenerationOptions,
): Promise<Uint8Array> {
  const { files, finishReason } = await generateText({
    model: vertexInteractionsModel(tryonVideoModel()),
    messages: [{
      role: "user",
      content: [
        { type: "text", text: buildVideoPrompt(opts) },
        {
          type: "file",
          data: tryonImageBase64,
          mediaType: detectMimeType(tryonImageBase64),
        },
      ],
    }],
    providerOptions: {
      google: {
        responseFormat: [{ type: "video", aspectRatio: "9:16" }],
      },
    },
    maxRetries: QUOTA_WINDOW_RETRIES,
  }).catch(rethrowAsBusy);

  const video = files.find((file) => file.mediaType.startsWith("video/"));
  if (!video) {
    throw new GenerationFailedError(
      `No video in Vertex response, finishReason: ${finishReason}`,
    );
  }
  return decodeBase64(video.base64);
}

/**
 * Half the SDK's default. The platform ends the request at 150s, so the poll
 * interval is the tail of that budget: at 10s a video that finished at 145s is
 * missed, at 5s it still makes it back.
 */
const POLL_INTERVAL_MS = 5000;

/**
 * Veo is long-running and this waits it out inside the request: a job outlives
 * a dropped connection but its result does not, so a caller that goes away
 * cannot pick it up again.
 *
 * The image goes in as bytes because the SDK would otherwise decode the base64
 * itself, with the same heap-hungry `Uint8Array.from(string)` as above, only
 * to re-encode it for the request.
 */
async function generateVeoVideo(
  tryonImageBase64: string,
  opts: VideoGenerationOptions,
): Promise<Uint8Array> {
  const { video } = await experimental_generateVideo({
    model: vertexVideoModel(tryonExperimentalVideoModel()),
    prompt: {
      image: decodeBase64(tryonImageBase64),
      text: buildVideoPrompt(opts),
    },
    aspectRatio: "9:16",
    providerOptions: { vertex: { pollIntervalMs: POLL_INTERVAL_MS } },
    maxRetries: QUOTA_WINDOW_RETRIES,
  }).catch(rethrowAsBusy);

  return decodeBase64(video.base64);
}

export function generateTryonVideo(
  tryonImageBase64: string,
  opts: VideoGenerationOptions = {},
): Promise<Uint8Array> {
  return opts.engine === "experimental"
    ? generateVeoVideo(tryonImageBase64, opts)
    : generateInteractionsVideo(tryonImageBase64, opts);
}
