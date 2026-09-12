/**
 * The prompt, the schema and the sanitiser belong together: structured output
 * types `garment_type` as a string, so the model has no way to answer "I can't tell"
 * with JSON null. `unknown` is the agreed spelling instead — the prompt teaches
 * it, the schema permits it, and the sanitiser strips it back out. Change one of
 * the three and the other two stop making sense.
 *
 * `tags` carries no enum, and the vocabulary the prompt lists is not enforced on
 * the way back: it steers the model towards labels the rest of the wardrobe
 * already uses, but a user may type any tag by hand
 * (`upload_wardrobe_item_sheet.dart`), so filtering the model's answer would
 * only make the AI's suggestions narrower than what they can enter themselves.
 */

import { GARMENT_TYPE_VALUES } from "../_shared/vocabularies.ts";

const UNKNOWN = "unknown";

/** Stated to the model, enforced on the way back. */
const MAX_TAGS = 6;

/**
 * The garment types a wardrobe item can land in — the values
 * `wardrobe_items.garment_type` accepts. {@link UNKNOWN} is offered by the
 * schema so the model has an explicit "can't tell" option, and is absent here
 * so it never reaches the response.
 */
const VALID_GARMENT_TYPES: readonly string[] = GARMENT_TYPE_VALUES;
const SCHEMA_GARMENT_TYPES = [...VALID_GARMENT_TYPES, UNKNOWN];

export const ANALYSIS_PROMPT =
  `你是時尚衣物標註助手。分析這張單一衣物的照片，輸出 JSON。
- garment_type 從以下擇一：top（上衣）, pants（褲子）, skirt（裙子）, dress（洋裝）, outerwear（外套）, others（其他，含套裝、鞋子、配件及無法歸類者）；無法判斷用 ${UNKNOWN}。
- tags 以「繁體中文」輸出，最多 ${MAX_TAGS} 個，只能從下列受控詞彙挑選：
  顏色：黑、白、灰、米、棕、紅、橙、黃、綠、藍、紫、粉、金、銀
  風格：休閒、正式、運動、復古、簡約、甜美、街頭
  材質：棉、牛仔、針織、皮革、雪紡、羊毛、丹寧
  版型/圖案：素色、條紋、格紋、印花、拼接、寬鬆、合身
只回 JSON，不要多餘文字。`;

export const ANALYSIS_SCHEMA: Record<string, unknown> = {
  type: "object",
  properties: {
    garment_type: { type: "string", enum: SCHEMA_GARMENT_TYPES },
    tags: { type: "array", items: { type: "string" } },
  },
  required: ["garment_type", "tags"],
};

export interface WardrobeAnalysisResponse {
  garment_type: string | null;
  tags: string[];
}

/**
 * A garment type outside {@link VALID_GARMENT_TYPES} comes back `null`, which
 * the app reads as "leave this input alone".
 *
 * Unlike its sibling in `analyze-product-image/analysis.ts`, this does not
 * de-dupe tags: that one filters against a closed enum, where a repeat is
 * redundant by construction; `tags` here is free text with no such vocabulary,
 * so a repeat is a fact about the model's answer, not noise to collapse.
 */
export function toResponse(
  parsed: Record<string, unknown>,
): WardrobeAnalysisResponse {
  const garment_type =
    typeof parsed.garment_type === "string" && VALID_GARMENT_TYPES.includes(parsed.garment_type)
      ? parsed.garment_type
      : null;

  const tags = Array.isArray(parsed.tags)
    ? parsed.tags
      .filter((t): t is string => typeof t === "string" && t.length > 0)
      .slice(0, MAX_TAGS)
    : [];

  return { garment_type, tags };
}
