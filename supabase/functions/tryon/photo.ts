import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { CONFIG } from "../_shared/supabase.ts";

const SYSTEM_INSTRUCTION =
  `You are a virtual try-on system. Your ONLY job is to dress the person in a new garment while preserving their identity exactly. 

CORE TASK: Remove the original clothing completely and replace it with the new garment. Think of this as a two-step process:
1. REMOVE: Completely erase all traces of the original clothing
2. REPLACE: Apply the new garment in its place

You must NEVER alter the person's face, body, hair, or pose. You must NEVER invent garment details that aren't in the reference image. You must NEVER leave remnants of the original clothing visible.`;

function buildTaskPrompt(clothesCount: number, scenePrompt?: string): string {
  let prompt =
    `You will receive ${clothesCount + 1} images after this message:
1) FIRST image: the PERSON photo — this is the target person. Keep them exactly as-is.
2) ALL SUBSEQUENT IMAGES: multiple REFERENCE photos of the EXACT SAME GARMENT from different angles. Use them ALL together to understand the garment's 3D structure, front/back designs, and patterns. Copy its design exactly.

GOAL
Create a photorealistic photo of the person from the first image wearing the garment from the reference images.

HARD INVARIANTS — DO NOT CHANGE THESE
- Person's face, expression, hair (color, length, style), skin tone, age, and body shape must be identical to the first image.
- Pose, camera angle, and body proportions must match the first image exactly.
- Do not add, remove, or alter tattoos, jewelry, accessories, hands, or fingers.
- Do not change the background from the first image${scenePrompt ? " (unless overridden by SCENE CONTEXT below)" : ""}.

GARMENT TRANSFER — MUST MATCH THE REFERENCE IMAGES EXACTLY
- Copy the garment precisely: silhouette, neckline shape, sleeve length, hem length, seams, stitching, closures (buttons/zippers), pockets, and any logos or text.
- Preserve print/pattern scale, placement, and color exactly — do not simplify or genericize.
- Maintain material properties: sheen, thickness, texture, translucency.
- Fit the garment naturally to this person's body: realistic drape, wrinkles, and tension points for their specific pose.

CRITICAL: ORIGINAL CLOTHING REMOVAL
- COMPLETELY REMOVE all traces of the person's original clothing from the first image.
- If the new garment has shorter sleeves (e.g., sleeveless, short sleeves) than the original, the person's arms MUST be fully visible with natural skin — NO remnants of original sleeves.
- If the new garment has a different neckline (e.g., lower cut, wider), the person's chest/shoulders MUST show natural skin — NO remnants of original collar or fabric.
- If the new garment is shorter in length, the person's torso/legs MUST be visible with natural skin — NO remnants of original hem.
- The boundary between the new garment and exposed skin must be clean, natural, and seamless with proper shadows and skin texture.
- Areas not covered by the new garment should show the person's natural body as if they were never wearing the original clothing.

EXAMPLE SCENARIOS
- Original: long-sleeved shirt → New: sleeveless top = Show full bare arms with natural skin tone and texture
- Original: turtleneck → New: V-neck = Show natural chest/collarbone area with no fabric remnants
- Original: full-length dress → New: short dress = Show natural legs below the new hem
- The key is: treat uncovered areas as if the person is wearing ONLY the new garment, nothing else.

SOURCE IMAGE ISOLATION
- Treat the garment reference images as product references ONLY.
- Ignore any model, mannequin, body, background, props, or lighting visible in the garment photos.
- Extract and transfer ONLY the garment itself.

LIGHTING & REALISM
- Match lighting direction, intensity, and color temperature from the person photo.
- Generate realistic shadows where fabric contacts the body.
- Soft diffused lighting, natural skin rendering, no artifacts, no warping, no halos, no double edges.

OUTPUT
- Return ONE image. Portrait 9:16 composition.
- Sharp garment detail, accurate color reproduction, fashion photography quality.`;

  if (scenePrompt) {
    prompt += `

SCENE CONTEXT — BACKGROUND ONLY
Place the person in this scene: ${scenePrompt}
- Change ONLY the background and adjust lighting to match the new environment.
- DO NOT change the person's identity, face, body, hair, pose, or any garment details.
- The garment must remain exactly as specified above.`;
  }

  return prompt;
}

function detectMimeType(base64Data: string): string {
  const header = atob(base64Data.slice(0, 16));
  if (header.startsWith("\x89PNG")) return "image/png";
  if (header.startsWith("\xFF\xD8\xFF")) return "image/jpeg";
  if (header.slice(0, 4) === "RIFF" && header.slice(8, 12) === "WEBP") {
    return "image/webp";
  }
  return "image/jpeg";
}

/**
 * Generate a try-on image using Gemini.
 * Returns the base64-encoded image or null if generation failed.
 */
export async function generateTryonImage(
  avatarImage: string,
  clothesImages: string[],
  scenePrompt?: string,
): Promise<string | null> {
  const genAI = new GoogleGenerativeAI(CONFIG.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: CONFIG.GEMINI_TRYON_MODEL,
    systemInstruction: SYSTEM_INSTRUCTION,
    generationConfig: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: "9:16",
      },
    },
  });

  const taskPrompt = buildTaskPrompt(clothesImages.length, scenePrompt);
  
  const parts: any[] = [
    { text: taskPrompt },
    {
      inlineData: {
        data: avatarImage,
        mimeType: detectMimeType(avatarImage),
      },
    },
  ];

  for (const img of clothesImages) {
    parts.push({
      inlineData: {
        data: img,
        mimeType: detectMimeType(img),
      },
    });
  }

  const result = await model.generateContent(parts);

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
