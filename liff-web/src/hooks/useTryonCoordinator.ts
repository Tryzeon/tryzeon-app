import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { tryonFailureMessage } from "../api/errors";
import { runTryon, type Garment } from "../api/tryon";
import { downscaleToBase64 } from "../lib/image";
import { newId } from "../lib/id";
import { loadPromptConfig } from "../lib/promptConfig";
import type { TryonProduct } from "../state/gallery";
import { useGallery } from "../state/GalleryProvider";

class SetupError extends Error {}

const SETUP_FALLBACK = "準備試穿失敗，請稍後再試。";

/** The single entry point for every try-on: those started from the product page
 * and from home all land in the same gallery. */
export function useTryonCoordinator() {
  const { dispatch } = useGallery();
  const navigate = useNavigate();

  const run = useCallback(
    async (buildGarment: () => Promise<Garment>, product: TryonProduct | null) => {
      // The placeholder page and the navigation come before any work: preparing a
      // try-on reads a file and downscales it. All of it happens after the button
      // is pressed, so doing it first would freeze the screen until it finished —
      // the animation goes up first and the work runs underneath it.
      const id = newId();
      dispatch({ type: "addPending", id, product });
      navigate("/home");

      let garment: Garment;
      try {
        garment = await buildGarment();
      } catch (err) {
        dispatch({
          type: "fail",
          id,
          message: err instanceof SetupError ? err.message : SETUP_FALLBACK,
        });
        return;
      }

      try {
        const imageUrl = await runTryon(garment, loadPromptConfig());
        dispatch({ type: "complete", id, imageUrl });
      } catch (err) {
        // `fail` rather than remove + notify: the user may already have cancelled
        // the generation, after which this request's fate should not bother them
        // — the reducer decides whether that page is still there.
        dispatch({ type: "fail", id, message: tryonFailureMessage(err) });
      }
    },
    [dispatch, navigate],
  );

  const fromGarmentPhoto = useCallback(
    (file: File) =>
      run(async () => {
        try {
          return { images: [{ base64: await downscaleToBase64(file) }] };
        } catch {
          throw new SetupError("讀取照片失敗，換一張再試。");
        }
      }, null),
    [run],
  );

  const fromProduct = useCallback(
    (item: CatalogItem) =>
      run(async () => ({ productId: item.productId }), {
        productId: item.productId,
        name: item.name,
      }),
    [run],
  );

  return { fromGarmentPhoto, fromProduct };
}
