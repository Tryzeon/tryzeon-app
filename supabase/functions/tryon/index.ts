import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { generateTryonImage } from "./photo.ts";
import { generateTryonVideo } from "./video.ts";

Deno.serve(async (req) => {
  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;
    const adminClient = getAdminClient();

    const bodyText = await req.text();
    if (!bodyText) {
      return new Response(
        JSON.stringify({ error: "Empty request body", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const body = JSON.parse(bodyText);
    const { avatarBase64, avatarPath, clothesBase64, clothesPath, mode = "photo" } = body;

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

    const featureName = mode === "video" ? "tryon_video" : "tryon";
    const { data: isAllowed, error: rpcError } = await adminClient.rpc(
      "increment_feature_usage",
      { p_user_id: user!.id, p_feature_name: featureName },
    );

    if (rpcError) {
      console.error("RPC Error:", rpcError);
      return new Response(
        JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!isAllowed) {
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

    const tryonImageBase64 = await generateTryonImage(avatarImage, clothesImage);

    if (!tryonImageBase64) {
      return new Response(
        JSON.stringify({ error: "Image generation failed", code: "AI_GENERATION_FAILED" }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    if (mode === "video") {
      const videoBase64 = await generateTryonVideo(tryonImageBase64);
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
    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
