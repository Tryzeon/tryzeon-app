/**
 * These are not a copy of the database's enums — `supabase gen types` emits a
 * runtime `Constants` object alongside the types, so they are the database's
 * enums, imported. A JSON Schema for a model and a Zod enum both need a real
 * array, and this is one. Adding a value in a migration and running
 * `./scripts/gen_supabase_types.sh` is the entire update.
 *
 * Values stay in English because that is what the app's Dart enums parse; the
 * Chinese a shopper sees is applied at display time in the app. The one
 * vocabulary the server also needs in Chinese is the style guide below.
 */
import { Constants } from "./database.types.ts";

const ENUMS = Constants.public.Enums;

export const ELASTICITY_VALUES = ENUMS.product_elasticity;
export const THICKNESS_VALUES = ENUMS.product_thickness;
export const FIT_VALUES = ENUMS.product_fit;
export const SEASON_VALUES = ENUMS.product_season;
export const CHANNEL_VALUES = ENUMS.store_channel;
export const GENDER_VALUES = ENUMS.product_gender;
export const GARMENT_TYPE_VALUES = ENUMS.garment_type;

/**
 * The exception. `products.styles` is `text[]` with no enum behind it, because
 * `ClothingStyle` is a vocabulary of subjective tags and the one most likely
 * to churn — the shape an enum handles worst. Nothing generates this list, so
 * its values and names must be kept in step with `ClothingStyle` in
 * `lib/feature/common/clothing_style/domain/entities/clothing_style.dart` by
 * hand, in the same order.
 *
 * The guide is what the models read: image analysis labels by the description,
 * and chat names the user's preferences and the search filter by it.
 */
export const STYLE_GUIDE = {
  basic: {
    name: "簡約基本",
    description:
      "素色、無印花、線條俐落的基本款，如素T、素面針織、素面襯衫、顏色均勻的直筒牛仔褲；只在沒有其他風格特徵時才選",
  },
  casual: {
    name: "休閒日常",
    description:
      "輕鬆隨性的日常款，如印字T恤、帽T、格紋襯衫、刷色牛仔褲、休閒寬褲",
  },
  business: {
    name: "通勤正式",
    description: "適合上班的俐落款，如襯衫、西裝褲、垂墜寬褲、西裝外套、套裝",
  },
  elegant: {
    name: "優雅氣質",
    description: "線條柔和、有質感，如針織開衫、百褶中長裙、垂墜洋裝、雪紡上衣",
  },
  sweet: {
    name: "甜美可愛",
    description:
      "有可愛的裝飾或配色，如蕾絲、荷葉邊、泡泡袖、蝴蝶結、碎花、粉嫩色",
  },
  streetwear: {
    name: "街頭潮流",
    description: "寬鬆有態度的潮流款，如 oversized、大 logo、印花帽T、工裝褲",
  },
  sporty: {
    name: "運動機能",
    description:
      "有運動或機能感，如防風外套、機能束口褲、運動背心、瑜珈褲、登山外套",
  },
  vintage: {
    name: "復古",
    description: "帶有年代感，如燈芯絨、喇叭褲、復古印花、老派格紋",
  },
  preppy: {
    name: "學院",
    description: "校園感，如針織背心、百褶裙、Polo衫、格紋裙",
  },
  edgy: {
    name: "個性酷帥",
    description: "帥氣、帶點叛逆感，如皮夾克、短靴、銀飾、中性剪裁",
  },
  natural: {
    name: "文青自然",
    description: "自然、鬆弛的質感，如棉麻、大地色、寬鬆版型、碎花長洋裝",
  },
  party: {
    name: "性感派對",
    description:
      "展現身材曲線或適合派對，如細肩帶、短版露腰、貼身短裙、露肩上衣、緞面、亮片",
  },
  homewear: {
    name: "居家舒適",
    description: "在家穿的柔軟寬鬆款，如睡衣、家居服、居家棉褲",
  },
} as const;

export type StyleValue = keyof typeof STYLE_GUIDE;

export const STYLE_VALUES = Object.keys(STYLE_GUIDE) as [
  StyleValue,
  ...StyleValue[],
];

export const styleName = (value: string): string =>
  (STYLE_GUIDE as Record<string, { name: string }>)[value]?.name ?? value;

export const describeStyles = (): string =>
  STYLE_VALUES.map((value) =>
    `${value}（${STYLE_GUIDE[value].name}）：${STYLE_GUIDE[value].description}`
  ).join("\n  ");
