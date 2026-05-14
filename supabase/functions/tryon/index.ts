import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager, FeatureName } from "../_shared/quota.ts";
import { fetchImageAsBase64, detectMimeType, mimeTypeToExtension, base64ToUint8Array } from "../_shared/image-utils.ts";
import { uploadImageToR2 } from "../_shared/r2.ts";
import { generateTryonImage } from "./image.ts";
import { generateTryonVideo } from "./video.ts";

Deno.serve(async (req) => {
  let quotaManager: QuotaManager | undefined;

  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const adminClient = getAdminClient();

    let body;
    try {
      const bodyText = await req.text();
      body = JSON.parse(bodyText);
    } catch (err) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON format", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    const { avatarBase64, avatarPath, clothesBase64s, clothesPaths, mode = "image", scenePrompt, transitionPrompt } = body;

    if (!avatarPath && !avatarBase64) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    if ((!clothesBase64s || clothesBase64s.length === 0) && (!clothesPaths || clothesPaths.length === 0)) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const featureName: FeatureName = mode === "video" ? "tryon_video" : "tryon";
    quotaManager = new QuotaManager(adminClient, user!.id, featureName);

    const { allowed, usage } = await quotaManager.incrementQuota();
    if (!allowed) {
      return new Response(
        JSON.stringify({
          error: "Rate limit exceeded",
          code: "RATE_LIMIT_EXCEEDED",
          usage: usage,
        }),
        { status: 429, headers: { "Content-Type": "application/json" } },
      );
    }

    const avatarImage = avatarBase64 ? avatarBase64 : await fetchImageAsBase64(userClient!, avatarPath!);
    let clothesImages: string[] = [];

    if (clothesBase64s && clothesBase64s.length > 0) {
      clothesImages = clothesBase64s.slice(0, 3);
    } else if (clothesPaths && clothesPaths.length > 0) {
      const pathsToFetch = clothesPaths.slice(0, 3);
      clothesImages = await Promise.all(pathsToFetch.map((p: string) => fetchImageAsBase64(userClient!, p)));
    }

    const tryonImageBase64 = await generateTryonImage(avatarImage, clothesImages, scenePrompt);

    if (!tryonImageBase64) {
      return new Response(
        JSON.stringify({ error: "Image generation failed", code: "AI_GENERATION_FAILED" }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    if (mode === "video") {
      const videoUrl = await generateTryonVideo(tryonImageBase64, user!.id, transitionPrompt);
      return new Response(
        JSON.stringify({ videoUrl: videoUrl, usage: usage }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const cleanBase64 = tryonImageBase64.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);

    const bytes = base64ToUint8Array(cleanBase64);
    const imageBuffer = bytes.buffer;

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const fileName = `${user!.id}/${timestamp}.${extension}`;

    const imageUrl = await uploadImageToR2(imageBuffer, fileName, mimeType);

    return new Response(
      JSON.stringify({ imageUrl: imageUrl, usage: usage }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Unexpected error:", err);

    await quotaManager?.rollbackQuota();

    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
