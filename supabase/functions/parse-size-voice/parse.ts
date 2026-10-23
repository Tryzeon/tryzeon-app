import { jsonError } from "../_shared/http.ts";

/// Garment measurements — must stay in sync with GarmentMeasurementType
/// in lib/feature/common/product_size/domain/entities/.
export const MEASUREMENT_KEYS = [
  "shoulder_width",
  "chest_circumference",
  "sleeve_length",
  "waist_circumference",
  "hip_circumference",
  "thigh_circumference",
  "length",
  "leg_opening",
] as const;

/// Recommended wearer body ranges — must stay in sync with `BodyMeasurementType`
/// in lib/feature/common/body_measurements/domain/entities/body_measurement_type.dart.
/// Weight is kilograms, everything else centimeters; none takes a spoken unit.
export const BODY_MEASUREMENT_RANGE_KEYS = [
  "height",
  "weight",
  "shoulder",
  "chest",
  "waist",
  "hips",
  "thigh",
] as const;

export const UNIT_VALUES = ["centimeter", "cun", "inch"] as const;
export type Unit = (typeof UNIT_VALUES)[number];

const isUnit = (v: unknown): v is Unit => (UNIT_VALUES as readonly unknown[]).includes(v);

/// Only the ingestion path normalizes: what a store owner types by hand is kept
/// verbatim, because a custom size name is their decision. Values must stay in
/// sync with StandardSizeLabel.display in
/// lib/feature/common/product_size/domain/entities/standard_size_label.dart.
const SIZE_NAME_ALIASES: Record<string, string> = {
  "XS": "XS",
  "EXTRASMALL": "XS",
  "S": "S",
  "SMALL": "S",
  "M": "M",
  "MEDIUM": "M",
  "MED": "M",
  "L": "L",
  "LARGE": "L",
  "XL": "XL",
  "1XL": "XL",
  "EXTRALARGE": "XL",
  "2XL": "2XL",
  "XXL": "2XL",
  "F": "均碼",
  "FREE": "均碼",
  "FREESIZE": "均碼",
  "ONESIZE": "均碼",
  "均碼": "均碼",
  "均一": "均碼",
  "單一尺寸": "均碼",
};

export function normalizeSizeName(raw: string): string {
  const trimmed = raw.trim();
  const key = trimmed.toUpperCase().replace(/[\s\-_]/g, "");
  return SIZE_NAME_ALIASES[key] ?? trimmed;
}

const MAX_AUDIO_BASE64_LENGTH = 10 * 1024 * 1024; // ~7.5MB binary, well above 60s AAC
const SUPPORTED_MIME = new Set([
  "audio/mp4",
  "audio/aac",
  "audio/mpeg",
  "audio/mp3",
  "audio/wav",
  "audio/x-m4a",
]);

/**
 * 寸 and 吋 are both read "cùn", so a bare one cannot say 台寸 from inch. The
 * store's own unit settles it when that unit is one of the two; otherwise inch,
 * the one Taiwanese apparel listings mean by a bare 吋.
 */
function bareCunUnit(currentUnit: Unit): Unit {
  return currentUnit === "centimeter" ? "inch" : currentUnit;
}

export function buildPrompt(currentUnit: Unit): string {
  return [
    "你是服裝尺寸資料整理助手。輸入是一段店家的口語錄音（主要為繁體中文，尺寸代號可能夾雜英文如 M、L、US 10）。",
    "請從語音中萃取每一個尺寸與其量測值，輸出 JSON。",
    "規則：",
    "1. 忽略口頭禪、語助詞、重複與與尺寸無關的閒聊，只保留尺寸資訊（去贅字）。",
    "2. garment_measurements 是陣列，每個講到的量測一筆，type 只允許：shoulder_width(肩寬)、chest_circumference(胸圍)、sleeve_length(袖長)、waist_circumference(腰圍)、hip_circumference(臀圍)、thigh_circumference(大腿圍)、length(長度)、leg_opening(褲口寬)。沒講到的量測不要輸出；一個都沒講到就給空陣列。",
    "2-0. length 是衣服本身的長度，衣長、褲長、裙長、洋裝長一律填 length。",
    "2-1. garment_measurements 是「衣服」的尺寸，不是人體的尺寸。身高、體重絕對不要放進 garment_measurements。",
    "2-2. 胸圍、腰圍、臀圍、大腿圍是該部位一圈的長度。店家若說的是「平放衣服量的胸寬／腰寬／臀寬／大腿寬」（半圈），請乘以 2 後填入對應的圍度欄位。",
    "3. 每個量測輸出 { type, value, unit }。value 為數字。",
    `4. unit 依口語判斷：說「公分」填 centimeter、說「台寸」填 cun、說「英吋」或 inch 填 inch。只說「寸」或「吋」時填 ${
      bareCunUnit(currentUnit)
    }。完全沒提單位時填 ${currentUnit}。`,
    "5. name 填聽到的尺寸代號（例 M、L、US 10）；若聽不出名稱填空字串。標準尺碼一律用 XS、S、M、L、XL、2XL、均碼 這幾個字面值（例如聽到「XXL」填 2XL、「free size」填 均碼）；不屬於標準尺碼的照聽到的原樣填。",
    "6. 若聽不出任何尺寸，sizes 回空陣列。",
    "7. 店家若說某尺寸「適合／建議身高 160 到 170、體重 50 到 60」，這是建議穿著者的身形範圍，輸出到 body_measurement_ranges 陣列，每筆 { type, min, max }：type 為 height（公分）或 weight（公斤）。只說單一數字（例如「適合 165」）時 min 與 max 都填該數字。沒講到的不要輸出；一個都沒講到就給空陣列。",
    "7-1. 肩寬、胸圍、腰圍、臀圍、大腿圍也可以是穿著者的身形範圍：店家說「適合／建議胸圍 88 到 96 的人穿」這類明確指人體的說法時，輸出到 body_measurement_ranges，type 為 shoulder、chest、waist、hips、thigh（公分）。沒有說「適合／建議」、只是報一個數字的，仍然是衣服尺寸，填 garment_measurements。",
  ].join("\n");
}

/**
 * Measurements are arrays of typed entries, and every key is required, because
 * Vertex writes an object's optional keys in a fixed order: a model that starts
 * with the shoulder width it heard first cannot go back for the chest, and puts
 * that number under a later key instead. An array takes them in spoken order.
 */
export function buildSchema(): Record<string, unknown> {
  const measurement = {
    type: "object",
    properties: {
      type: { type: "string", enum: [...MEASUREMENT_KEYS] },
      value: { type: "number" },
      unit: { type: "string", enum: [...UNIT_VALUES] },
    },
    required: ["type", "value", "unit"],
  };
  const range = {
    type: "object",
    properties: {
      type: { type: "string", enum: [...BODY_MEASUREMENT_RANGE_KEYS] },
      min: { type: "number" },
      max: { type: "number" },
    },
    required: ["type", "min", "max"],
  };
  return {
    type: "object",
    properties: {
      sizes: {
        type: "array",
        items: {
          type: "object",
          properties: {
            name: { type: "string" },
            garment_measurements: { type: "array", items: measurement },
            body_measurement_ranges: { type: "array", items: range },
          },
          required: ["name", "garment_measurements", "body_measurement_ranges"],
        },
      },
    },
    required: ["sizes"],
  };
}

export function validateRequest(body: unknown): {
  ok: true;
  base64: string;
  mimeType: string;
  currentUnit: Unit;
} | {
  ok: false;
  response: Response;
} {
  const { audioBase64, mimeType, currentUnit } = (body ?? {}) as Record<string, unknown>;
  if (typeof audioBase64 !== "string" || audioBase64.length < 16) {
    return {
      ok: false,
      response: jsonError("Missing or invalid audio", "BAD_REQUEST", 400),
    };
  }
  if (audioBase64.length > MAX_AUDIO_BASE64_LENGTH) {
    return {
      ok: false,
      response: jsonError("Audio payload too large", "PAYLOAD_TOO_LARGE", 413),
    };
  }
  const mime = typeof mimeType === "string" ? mimeType : "";
  if (!SUPPORTED_MIME.has(mime)) {
    return {
      ok: false,
      response: jsonError("Unsupported audio mime type", "BAD_REQUEST", 400),
    };
  }
  if (!isUnit(currentUnit)) {
    return {
      ok: false,
      response: jsonError("Missing or invalid currentUnit", "BAD_REQUEST", 400),
    };
  }
  return { ok: true, base64: audioBase64, mimeType: mime, currentUnit };
}

function toNumber(v: unknown): number | null {
  return typeof v === "number" && Number.isFinite(v) ? v : null;
}

export interface ParsedSize {
  name: string;
  garment_measurements: Record<string, { value: number; unit: string }>;
  body_measurement_ranges: Record<string, { min: number; max: number }>;
}

const isMeasurementKey = (v: unknown): v is (typeof MEASUREMENT_KEYS)[number] =>
  (MEASUREMENT_KEYS as readonly unknown[]).includes(v);

const isBodyMeasurementRangeKey = (v: unknown): v is (typeof BODY_MEASUREMENT_RANGE_KEYS)[number] =>
  (BODY_MEASUREMENT_RANGE_KEYS as readonly unknown[]).includes(v);

const entries = (raw: unknown): Record<string, unknown>[] =>
  Array.isArray(raw)
    ? raw.filter((e): e is Record<string, unknown> => e !== null && typeof e === "object")
    : [];

// A type spoken twice keeps its last value: a store owner who repeats a
// measurement is correcting it.
function normalizeGarmentMeasurements(raw: unknown): ParsedSize["garment_measurements"] {
  const out: ParsedSize["garment_measurements"] = {};
  for (const e of entries(raw)) {
    const value = toNumber(e.value);
    if (!isMeasurementKey(e.type) || !isUnit(e.unit) || value === null) continue;
    out[e.type] = { value, unit: e.unit };
  }
  return out;
}

function normalizeBodyMeasurementRanges(raw: unknown): ParsedSize["body_measurement_ranges"] {
  const out: ParsedSize["body_measurement_ranges"] = {};
  for (const e of entries(raw)) {
    const min = toNumber(e.min);
    const max = toNumber(e.max);
    if (!isBodyMeasurementRangeKey(e.type) || min === null || max === null) continue;
    out[e.type] = { min, max };
  }
  return out;
}

/**
 * Turns the model's typed-entry arrays back into the keyed shape the app reads,
 * so the schema's layout stays a detail between this function and the model.
 *
 * Only the shape is checked here. Whether a value is plausible is the size
 * form's call, for spoken and typed values alike, so a misheard number reaches
 * the store owner as a flagged cell instead of vanishing.
 */
export function normalizeParsedSizes(raw: unknown): ParsedSize[] {
  return entries((raw as { sizes?: unknown })?.sizes).map((s) => ({
    name: typeof s.name === "string" ? normalizeSizeName(s.name.slice(0, 20)) : "",
    garment_measurements: normalizeGarmentMeasurements(s.garment_measurements),
    body_measurement_ranges: normalizeBodyMeasurementRanges(s.body_measurement_ranges),
  }));
}
