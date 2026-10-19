import { supabase } from "../lib/supabase";
import { FunctionsHttpError } from "@supabase/supabase-js";
import { parseQuotaSnapshot, QuotaExhaustedError, toApiError } from "./errors";

export type Garment =
  | { productId: string }
  | { wardrobeItemId: string }
  | { images: { base64: string }[] };

export interface TryonOptions {
  scenePrompt?: string;
  stylingPrompt?: string;
}

/**
 * Image only — video try-on is not enabled on LIFF: that path is a ~5 minute
 * synchronous request, and the result is lost for good if the webview is
 * backgrounded.
 */
interface TryonBody extends TryonOptions {
  mode: "image";
  garments: Garment[];
}

async function toTryonError(error: unknown): Promise<Error> {
  if (error instanceof FunctionsHttpError && (error.context as Response).status === 429) {
    const body: unknown = await (error.context as Response).json().catch(() => null);
    const quota = (body as { quota?: unknown } | null)?.quota;
    return new QuotaExhaustedError(parseQuotaSnapshot(quota));
  }
  return toApiError(error);
}

/**
 * Calls the same tryon function the app uses, with the JWT attached by
 * supabase-js, so the whole job runs under RLS. An omitted field means
 * "unspecified" — an empty string would be taken by the backend as a real
 * prompt.
 */
export async function runTryon(
  garments: Garment[],
  { scenePrompt, stylingPrompt }: TryonOptions = {},
): Promise<string> {
  const body: TryonBody = {
    mode: "image",
    garments,
    ...(scenePrompt ? { scenePrompt } : {}),
    ...(stylingPrompt ? { stylingPrompt } : {}),
  };

  const { data, error } = await supabase.functions.invoke("tryon", { body });
  if (error) throw await toTryonError(error);

  const imageUrl = (data as { imageUrl?: unknown } | null)?.imageUrl;
  if (typeof imageUrl !== "string" || imageUrl.length === 0) {
    throw new Error("tryon response missing imageUrl");
  }
  return imageUrl;
}
