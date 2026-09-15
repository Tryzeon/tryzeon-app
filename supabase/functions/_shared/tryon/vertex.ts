/**
 * Owns what is provider-specific; builds no prompts (see `prompt.ts`) and
 * persists nothing.
 */
import { experimental_generateVideo, generateText } from "ai";
import { base64ToUint8Array, detectMimeType } from "../image-utils.ts";
import {
  tryonExperimentalImageModel,
  tryonExperimentalVideoModel,
  tryonImageModel,
  tryonVideoModel,
} from "../vertex/config.ts";
import { rethrowAsBusy } from "../vertex/errors.ts";
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
  // experimental model must still serve standard jobs.
  const modelName = opts.engine === "experimental"
    ? tryonExperimentalImageModel()
    : tryonImageModel();

  const { files, finishReason } = await generateText({
    model: vertexModel(modelName),
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
        imageConfig: { aspectRatio: "9:16" },
      },
    },
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
  }).catch(rethrowAsBusy);

  const video = files.find((file) => file.mediaType.startsWith("video/"));
  if (!video) {
    throw new GenerationFailedError(
      `No video in Vertex response, finishReason: ${finishReason}`,
    );
  }
  return video.uint8Array;
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
 */
async function generateVeoVideo(
  tryonImageBase64: string,
  opts: VideoGenerationOptions,
): Promise<Uint8Array> {
  const { video } = await experimental_generateVideo({
    model: vertexVideoModel(tryonExperimentalVideoModel()),
    prompt: {
      image: tryonImageBase64,
      text: buildVideoPrompt(opts),
    },
    aspectRatio: "9:16",
    providerOptions: { vertex: { pollIntervalMs: POLL_INTERVAL_MS } },
  }).catch(rethrowAsBusy);

  return base64ToUint8Array(video.base64);
}

export function generateTryonVideo(
  tryonImageBase64: string,
  opts: VideoGenerationOptions = {},
): Promise<Uint8Array> {
  return opts.engine === "experimental"
    ? generateVeoVideo(tryonImageBase64, opts)
    : generateInteractionsVideo(tryonImageBase64, opts);
}
