import {
  downloadPublicImageAsBase64,
  downloadStorageImageAsBase64,
} from "../image-utils.ts";
import type { ImageSource, ResolvedGarment } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export type SourceLoader = (source: ImageSource) => Promise<string>;

export function makeSourceLoader(
  client: DbClient,
  downloadPublicImage: (key: string) => Promise<string> =
    downloadPublicImageAsBase64,
): SourceLoader {
  return (source: ImageSource): Promise<string> => {
    if ("base64" in source) return Promise.resolve(source.base64);
    if ("publicImageKey" in source) {
      return downloadPublicImage(source.publicImageKey);
    }
    return downloadStorageImageAsBase64(client, source.bucket, source.path);
  };
}

export function loadGarments(
  garments: ResolvedGarment[],
  load: SourceLoader,
): Promise<string[][]> {
  return Promise.all(
    garments.map((garment) => Promise.all(garment.images.map(load))),
  );
}
