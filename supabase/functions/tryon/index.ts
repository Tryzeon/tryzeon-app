// current model: nano-banana-pro-preview
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { CONFIG, getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  try {
    // Auth & Setup
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;
    const adminClient = getAdminClient();

    // Parse Body
    const bodyText = await req.text();
    if (!bodyText) {
      return new Response(
        JSON.stringify({ error: "Empty request body", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const body = JSON.parse(bodyText);
    const { avatarBase64, avatarPath, clothesBase64, clothesPath } = body;

    if (!avatarPath && !avatarBase64) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    if (!clothesPath && !clothesBase64) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // User Quota Limit Check via RPC
    const { data: isAllowed, error: rpcError } = await adminClient.rpc(
      "increment_feature_usage",
      { p_user_id: user!.id, p_feature_name: "tryon" }
    );

    if (rpcError) {
      console.error("RPC Error:", rpcError);
      return new Response(
        JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!isAllowed) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }),
        { status: 429, headers: { "Content-Type": "application/json" } }
      );
    }

    // Storage Fetch Helper
    const fetchImageBase64 = async (path: string) => {
      let bucket: string;
      if (path.includes('wardrobe')) bucket = 'wardrobe-images';
      else if (path.includes('product')) bucket = 'product-images';
      else if (path.includes('avatar')) bucket = 'user-avatars';
      else throw new Error(`Cannot determine bucket from path: ${path}`);

      const { data, error } = await userClient!.storage.from(bucket).download(path);
      if (error) throw new Error(`Failed to download image from ${bucket}/${path}: ${error.message}`);

      const buf = new Uint8Array(await data!.arrayBuffer());
      return btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
    };

    const avatarImage = avatarBase64 ? avatarBase64 : await fetchImageBase64(avatarPath!);
    const clothesImage = clothesBase64 ? clothesBase64 : await fetchImageBase64(clothesPath!);

    // Generate Try-on via Gemini
    const genAI = new GoogleGenerativeAI(CONFIG.GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({
      model: CONFIG.GEMINI_TRYON_MODEL,
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: { aspect_ratio: "9:16" }
      }
    });

    const prompt = "Please dress the person in the first photo with the clothes from the second photo, keeping the person's face clear and posture natural, generating a complete composite image. It is extremely important that the details, wrinkles, patterns, styling, and overall look of the clothing when worn by the model are exactly consistent with the original clothing in the second photo. Output in a vertical 9:16 aspect ratio.";

    const result = await model.generateContent([
      { text: prompt },
      { inlineData: { data: avatarImage, mimeType: "image/jpeg" } },
      { inlineData: { data: clothesImage, mimeType: "image/jpeg" } }
    ]);

    const candidates = result.response.candidates ?? [];
    for (const c of candidates) {
      for (const p of c.content.parts ?? []) {
        if (p.inlineData?.mimeType?.startsWith("image/")) {
          const resultImageBase64 = p.inlineData.data;

          return new Response(JSON.stringify({ image: `data:image/png;base64,${resultImageBase64}` }), {
            headers: { "Content-Type": "application/json" }
          });
        }
      }
    }

    return new Response(
      JSON.stringify({ error: "Image generation failed", code: "AI_GENERATION_FAILED" }),
      { status: 422, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});