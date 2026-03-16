import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { CONFIG } from "../_shared/supabase.ts";

const DEFAULT_PHOTO_PROMPT =
  "Please dress the person in the first photo with the clothes from the second photo, keeping the person's face clear and posture natural, generating a complete composite image. It is extremely important that the details, wrinkles, patterns, styling, and overall look of the clothing when worn by the model are exactly consistent with the original clothing in the second photo. Output in a vertical 9:16 aspect ratio.";

function buildPhotoPrompt(scenePrompt?: string): string {
  if (!scenePrompt) {
    return DEFAULT_PHOTO_PROMPT;
  }

  return `Please dress the person in the first photo with the clothes from the second photo, keeping the person's face clear and posture natural, generating a complete composite image. Scene setting: ${scenePrompt}. It is extremely important that the details, wrinkles, patterns, styling, and overall look of the clothing when worn by the model are exactly consistent with the original clothing in the second photo. Output in a vertical 9:16 aspect ratio.`;
}

/**
 * Generate a try-on image using Gemini.
 * Returns the base64-encoded image or null if generation failed.
 */
export async function generateTryonImage(
  avatarImage: string,
  clothesImage: string,
  scenePrompt?: string,
): Promise<string | null> {
  const genAI = new GoogleGenerativeAI(CONFIG.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: CONFIG.GEMINI_TRYON_MODEL,
    generationConfig: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: { aspect_ratio: "9:16" },
    },
  });

  const prompt = buildPhotoPrompt(scenePrompt);
  const result = await model.generateContent([
    { text: prompt },
    { inlineData: { data: avatarImage, mimeType: "image/jpeg" } },
    { inlineData: { data: clothesImage, mimeType: "image/jpeg" } },
  ]);

  const candidates = result.response.candidates ?? [];

  for (const c of candidates) {
    for (const p of c.content.parts ?? []) {
      if (p.inlineData?.mimeType?.startsWith("image/")) {
        return p.inlineData.data;
      }
    }
  }

  return null;
}
