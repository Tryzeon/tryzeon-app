/**
 * Policy: normalization never silently changes the meaning of user input — it
 * only trims and narrows shapes. Every limit is enforced by
 * `validateTryonParams`, which throws. Truncation is reserved for text the
 * server assembles from its own rows (see `buildProductGarmentDetail`), so a
 * caller is never told "accepted" while its input was quietly cut short.
 */
import { requireString, ValidationError } from "../validation.ts";
import { isUuid } from "../text.ts";
import { isProductRef, isWardrobeRef, LIMITS } from "./types.ts";
import type {
  GarmentInput,
  ProductRef,
  TryonEngine,
  TryonParams,
} from "./types.ts";

/**
 * The entry point reads the whole body into memory before any guard here runs,
 * so without a ceiling an authenticated caller could spend a function's memory
 * — and a quota charge — on something the model was going to reject anyway.
 */
function requireBase64(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ValidationError(`${label} must have a non-empty base64`);
  }
  if (value.length > LIMITS.MAX_BASE64_LENGTH) {
    throw new ValidationError(
      `${label} too large (max ${LIMITS.MAX_BASE64_LENGTH} base64 chars)`,
    );
  }
  return value;
}

function requireInlineImage(
  source: unknown,
  label: string,
): { base64: string } {
  if (typeof source !== "object" || source === null) {
    throw new ValidationError(`${label} must be an object`);
  }
  const base64 = (source as Record<string, unknown>).base64;
  return { base64: requireBase64(base64, label) };
}

function assertOptionalText(value: unknown, label: string, max: number): void {
  if (value === undefined) return;
  if (typeof value !== "string") {
    throw new ValidationError(`${label} must be a string`);
  }
  if (value.length > max) {
    throw new ValidationError(`${label} too long (max ${max})`);
  }
}

function validateGarment(garment: GarmentInput): GarmentInput {
  if (typeof garment !== "object" || garment === null) {
    throw new ValidationError("each garment must be an object");
  }
  if (isProductRef(garment)) {
    const ref: ProductRef = {
      productId: requireString(garment.productId, "garment productId"),
    };
    if (garment.sizeId !== undefined) {
      ref.sizeId = requireString(garment.sizeId, "garment sizeId");
    }
    return ref;
  }
  if (isWardrobeRef(garment)) {
    return {
      wardrobeItemId: requireString(
        garment.wardrobeItemId,
        "garment wardrobeItemId",
      ),
    };
  }
  if (!Array.isArray(garment.images) || garment.images.length === 0) {
    throw new ValidationError(
      "each garment must have a non-empty images array",
    );
  }
  if (garment.images.length > LIMITS.MAX_IMAGES_PER_GARMENT) {
    throw new ValidationError(
      `too many images for a garment (max ${LIMITS.MAX_IMAGES_PER_GARMENT})`,
    );
  }
  // No garment text to check: a caller cannot supply any. A resolver attaches
  // it after this guard has run, capped where it is built.
  return {
    images: garment.images.map((img) =>
      requireInlineImage(img, "garment image")
    ),
  };
}

/**
 * Defaulted rather than rejected: the engine only picks a model tier, so an
 * unrecognised value — a client ahead of or behind this deployment — should
 * still get a result on the standard model instead of a 400 for a setting it
 * cannot see or fix.
 */
function normalizeEngine(value: unknown): TryonEngine {
  if (value === undefined || value === null) return "standard";
  if (value === "standard" || value === "experimental") return value;
  console.warn(
    `[tryon] unknown engine ${JSON.stringify(value)}, using standard`,
  );
  return "standard";
}

/** Called by `runTryonJob`, so every caller (app, LIFF, LINE) is checked. */
export function validateTryonParams(params: TryonParams): TryonParams {
  requireString(params.userId, "userId");

  if (params.mode !== "image" && params.mode !== "video") {
    throw new ValidationError("mode must be 'image' or 'video'");
  }

  const engine = normalizeEngine(params.engine);

  if (
    params.generationId !== undefined &&
    (typeof params.generationId !== "string" || !isUuid(params.generationId))
  ) {
    throw new ValidationError("generationId must be a uuid");
  }

  assertOptionalText(
    params.scenePrompt,
    "scenePrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );
  assertOptionalText(
    params.stylingPrompt,
    "stylingPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );
  assertOptionalText(
    params.transitionPrompt,
    "transitionPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );

  if (!Array.isArray(params.garments) || params.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  if (params.garments.length > LIMITS.MAX_GARMENTS) {
    throw new ValidationError(`too many garments (max ${LIMITS.MAX_GARMENTS})`);
  }
  const garments = params.garments.map(validateGarment);

  return { ...params, engine, garments };
}
