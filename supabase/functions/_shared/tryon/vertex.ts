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
  tryonImageModels,
  tryonVideoModel,
} from "../vertex/config.ts";
import { rethrowAsBusy } from "../vertex/errors.ts";
import { QUOTA_WINDOW_RETRIES } from "../vertex/retry.ts";
import { GenerationFailedError } from "./errors.ts";
import {
  vertexInteractionsModel,
  vertexModel,
  vertexModelSweep,
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

/**
 * `responseModalities` and `imageConfig` are Gemini's own settings, so they
 * travel under `providerOptions.vertex` rather than as call options.
 */
export async function generateTryonImage(
  avatarImage: string,
  garmentGroups: string[][],
  opts: ImageGenerationOptions = {},
): Promise<string | null> {
  const taskPrompt = buildTaskPrompt(garmentGroups, opts);
  console.log("[tryon] task prompt:\n" + taskPrompt);

  // Read at call time, not at module load: a deployment missing the
  // experimental model must still serve standard jobs. Only the standard
  // engine sweeps models: the experimental engine is the one model it names.
  const model = opts.engine === "experimental"
    ? vertexModel(tryonExperimentalImageModel())
    : vertexModelSweep(tryonImageModels());

  const { files, finishReason } = await generateText({
    model,
    system: SYSTEM_INSTRUCTION,
    messages: [{
      role: "user",
      content: [
        {
          type: "text",
          text: taskPrompt,
        },
        imagePart(avatarImage),
        ...garmentGroups.flat().map(imagePart),
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
    maxRetries: QUOTA_WINDOW_RETRIES,
  }).catch(rethrowAsBusy);

  const image = files.find((file) => file.mediaType.startsWith("image/"));
  if (!image) {
    console.error("No image in Vertex response, finishReason:", finishReason);
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
