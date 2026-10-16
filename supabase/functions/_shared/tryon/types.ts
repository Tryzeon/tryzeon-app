import type { DailyUsage, UsageCounter } from "../quota.ts";
import { GARMENT_TYPE_VALUES } from "../vocabularies.ts";
import type { Enums } from "../database.types.ts";
import type { ImagePromptOptions, VideoPromptOptions } from "./prompt.ts";
import type { DbClient } from "../supabase.ts";

export type { UsageCounter };

export type GarmentType = Enums<"garment_type">;

/**
 * What the prompt reasons about, which is narrower than what a store or a
 * shopper tags a garment with: `pants` and `skirt` are one replacement scope,
 * and `others` names no scope at all, so it maps to nothing rather than to a
 * category the model would then apply.
 */
export type GarmentCategory = "top" | "bottom" | "full_body" | "outerwear";

const CATEGORY_BY_TYPE: Record<GarmentType, GarmentCategory | undefined> = {
  top: "top",
  outerwear: "outerwear",
  pants: "bottom",
  skirt: "bottom",
  one_piece: "full_body",
  others: undefined,
};

export function garmentCategoryOf(
  garmentType: GarmentType,
): GarmentCategory | undefined {
  return CATEGORY_BY_TYPE[garmentType];
}

export function isGarmentType(value: unknown): value is GarmentType {
  return typeof value === "string" &&
    (GARMENT_TYPE_VALUES as readonly string[]).includes(value);
}

/**
 * Server-side only: what a resolver produces after reading a row it checked
 * ownership on, so it is never decoded from untrusted input and needs no
 * runtime guard.
 */
export type ImageSource = { path: string } | { base64: string };

/**
 * `sizeId` is accepted and carried through unchanged but nothing reads it: the
 * prompt no longer describes how a size sits on the wearer, and the model is
 * left to judge that from the images alone.
 */
export interface ProductRef {
  productId: string;
  sizeId?: string;
}

/**
 * A reference and not a path, so binding the read to its owner is the core's
 * job rather than every adapter's — see `resolveWardrobeGarment`.
 */
export interface WardrobeRef {
  wardrobeItemId: string;
}

/**
 * Bytes and never a path: the LINE adapter runs on the admin client, where a
 * forwarded path reads the whole wardrobe bucket with nothing checking whose
 * it was. Anything stored is reached by reference instead, which the core
 * resolves against the job's own user.
 */
export interface GarmentMaterial {
  images: { base64: string }[];
}

/**
 * Declares its own `images` rather than extending {@link GarmentMaterial}: a
 * caller sends inline bytes, a resolver produces a storage key, and sharing one
 * field would force the looser of the two on both.
 */
export interface ResolvedGarment {
  images: ImageSource[];
  category?: GarmentCategory;
  detail?: string;
}

export type GarmentInput = ProductRef | WardrobeRef | GarmentMaterial;

export function isProductRef(garment: GarmentInput): garment is ProductRef {
  return "productId" in garment;
}

export function isWardrobeRef(garment: GarmentInput): garment is WardrobeRef {
  return "wardrobeItemId" in garment;
}

export type TryonMode = "image" | "video";

/**
 * Video goes through the same image pass, so this is not an image-mode-only
 * setting. Defaults to `standard`.
 */
export type TryonEngine = "standard" | "experimental";

export interface TryonParams {
  userId: string;
  garments: GarmentInput[];
  mode: TryonMode;
  engine?: TryonEngine;
  scenePrompt?: string;
  stylingPrompt?: string;
  transitionPrompt?: string;
  generationId?: string;
}

/*
 * `usage` is the caller's whole counter row for the day — every feature's
 * count, `chat_count` included — because that is what the client syncs its
 * usage cache from after any request that charges quota.
 */

export interface TryonImageResult {
  kind: "image";
  imageUrl: string;
  usage: DailyUsage | null;
}

export interface TryonVideoResult {
  kind: "video";
  videoUrl: string;
  usage: DailyUsage | null;
}

export type TryonResult = TryonImageResult | TryonVideoResult;

export type TryonResultFor<M extends TryonMode> = M extends "image"
  ? TryonImageResult
  : TryonVideoResult;

export const LIMITS = {
  MAX_GARMENTS: 3,
  MAX_IMAGES_PER_GARMENT: 3,
  MAX_GARMENT_DETAIL_LENGTH: 500,
  MAX_PROMPT_LENGTH: 1000,
  MAX_BASE64_LENGTH: 16 * 1024 * 1024,
} as const;

/**
 * Takes no client: the quota RPCs are `SECURITY DEFINER` and granted to
 * `service_role` alone — `refund` especially, since a user able to call it has
 * unlimited quota — so charging cannot run on the client a job reads with.
 * Binding the service-role key into the factory (see `supabaseQuota`) keeps
 * that credential in the adapter and hands the core a capability instead.
 */
export type QuotaFactory = (
  userId: string,
  mode: TryonMode,
) => UsageCounter;

/**
 * Records a finished try-on against the products it wore, for the store
 * dashboards. Service-role only for the same reason as {@link QuotaFactory}:
 * the LINE adapter has no session, so the writer must name the user itself,
 * and a client able to do that could inflate any store's counts.
 */
export type TryonRecorder = (
  userId: string,
  productIds: string[],
) => Promise<void>;

export interface GenerationStart {
  id?: string;
  userId: string;
  mode: TryonMode;
}

/**
 * The models that actually produced the result, which the engine alone does
 * not say: the standard engine may have answered from its fallback. An image
 * job generates no video.
 */
export interface GenerationOutcome {
  resultKey: string;
  imageModel: string;
  videoModel?: string;
}

/**
 * One row per generation, written on the service role for the same reason as
 * {@link TryonRecorder}. The adapter binds the channel, so the core never
 * learns where a job came from.
 */
export interface GenerationLog {
  start(entry: GenerationStart): Promise<string>;
  succeed(id: string, outcome: GenerationOutcome): Promise<void>;
  fail(id: string, errorMessage: string): Promise<void>;
}

/**
 * `base64` is clean image data: no data-URI prefix — stripping any provider
 * preamble is the implementation's job.
 */
export interface GeneratedImage {
  base64: string;
  model: string;
}

export type ImageGenerator = (
  avatarBase64: string,
  garmentGroups: string[][],
  opts?: ImageGenerationOptions,
) => Promise<GeneratedImage | null>;

/** `engine` names a model rather than text, so the prompt builders ignore it. */
export interface ImageGenerationOptions extends ImagePromptOptions {
  engine?: TryonEngine;
}

export interface VideoGenerationOptions extends VideoPromptOptions {
  engine?: TryonEngine;
}

export interface GeneratedVideo {
  bytes: Uint8Array;
  model: string;
}

export type VideoGenerator = (
  tryonImageBase64: string,
  opts?: VideoGenerationOptions,
) => Promise<GeneratedVideo>;

export type ImageUploader = (
  bytes: Uint8Array,
  fileName: string,
  contentType: string,
) => Promise<string>;

export type VideoUploader = (
  bytes: Uint8Array,
  fileName: string,
) => Promise<string>;

export type ProductResolver = (
  client: DbClient,
  ref: ProductRef,
) => Promise<ResolvedGarment>;

/**
 * Takes the owner as well as the id: a wardrobe read is only correct bound to
 * whose wardrobe it is, and the binding is written out rather than left to RLS
 * because the LINE adapter passes a client with no policy beneath it.
 */
export type WardrobeResolver = (
  client: DbClient,
  userId: string,
  wardrobeItemId: string,
) => Promise<ResolvedGarment>;

export type AvatarResolver = (
  client: DbClient,
  userId: string,
) => Promise<ImageSource>;
