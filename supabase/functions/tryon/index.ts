import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager, FeatureName } from "../_shared/quota.ts";
import { generateTryonImage } from "./photo.ts";
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
    const { avatarBase64, avatarPath, clothesBase64, clothesPath, mode = "photo", scenePrompt, transitionPrompt } = body;

    if (!avatarPath && !avatarBase64) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    if (!clothesPath && !clothesBase64) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const featureName: FeatureName = mode === "video" ? "tryon_video" : "tryon";
    quotaManager = new QuotaManager(adminClient, user!.id, featureName);

    const canProceed = await quotaManager.incrementQuota();
    if (!canProceed) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }),
        { status: 429, headers: { "Content-Type": "application/json" } },
      );
    }

    const fetchImageBase64 = async (path: string) => {
      let bucket: string;
      if (path.includes("wardrobe")) bucket = "wardrobe-images";
      else if (path.includes("product")) bucket = "product-images";
      else if (path.includes("avatar")) bucket = "user-avatars";
      else throw new Error(`Cannot determine bucket from path: ${path}`);

      const { data, error } = await userClient!.storage.from(bucket).download(path);
      if (error) throw new Error(`Failed to download image from ${bucket}/${path}: ${error.message}`);

      const buf = new Uint8Array(await data!.arrayBuffer());
      return btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
    };

    const avatarImage = avatarBase64 ? avatarBase64 : await fetchImageBase64(avatarPath!);
    const clothesImage = clothesBase64 ? clothesBase64 : await fetchImageBase64(clothesPath!);

    const tryonImageBase64 = await generateTryonImage(avatarImage, clothesImage, scenePrompt);

    if (!tryonImageBase64) {
      return new Response(
        JSON.stringify({ error: "Image generation failed", code: "AI_GENERATION_FAILED" }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    if (mode === "video") {
      const videoBase64 = await generateTryonVideo(tryonImageBase64, transitionPrompt);
      return new Response(
        JSON.stringify({ video: videoBase64 }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ image: tryonImageBase64 }),
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
