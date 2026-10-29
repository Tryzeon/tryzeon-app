import { useCallback } from "react";
import { useNavigate } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import type { CatalogColor } from "../api/catalog-row";
import { tryonFailureMessage } from "../api/errors";
import { runTryon, type Garment } from "../api/tryon";
import { productCaption, productGarment } from "../lib/garment";
import { downscaleToBase64 } from "../lib/image";
import { newId } from "../lib/id";
import { loadPromptConfig } from "../lib/promptConfig";
import { useGallery } from "../state/GalleryProvider";

/** The single entry point for every try-on: those started from the product page
 * and from home all land in the same gallery. */
export function useTryonCoordinator() {
  const { dispatch } = useGallery();
  const navigate = useNavigate();

  // The placeholder page and the navigation come before any work: reading and
  // downscaling a photo happens after the button is pressed, so doing it first
  // would freeze the screen until it finished — the animation goes up first and
  // the work runs underneath it.
  const begin = useCallback(
    (caption: string | null) => {
      const id = newId();
      dispatch({ type: "addPending", id, caption });
      navigate("/home");
      return id;
    },
    [dispatch, navigate],
  );

  const submit = useCallback(
    async (id: string, garments: Garment[]) => {
      try {
        const imageUrl = await runTryon(garments, loadPromptConfig());
        dispatch({ type: "complete", id, imageUrl });
      } catch (err) {
        // `fail` rather than remove + notify: the user may already have cancelled
        // the generation, after which this request's fate should not bother them
        // — the reducer decides whether that page is still there.
        dispatch({ type: "fail", id, message: tryonFailureMessage(err) });
      }
    },
    [dispatch],
  );

  const fromGarmentPhoto = useCallback(
    async (file: File) => {
      const id = begin(null);
      let base64: string;
      try {
        base64 = await downscaleToBase64(file);
      } catch {
        dispatch({ type: "fail", id, message: "讀取照片失敗，換一張再試。" });
        return;
      }
      await submit(id, [{ images: [{ base64 }] }]);
    },
    [begin, submit, dispatch],
  );

  const fromProduct = useCallback(
    (item: CatalogItem, color: CatalogColor) =>
      submit(begin(productCaption(item, color)), [productGarment(item, color)]),
    [begin, submit],
  );

  const fromGarments = useCallback(
    (garments: Garment[], caption: string) => submit(begin(caption), garments),
    [begin, submit],
  );

  return { fromGarmentPhoto, fromProduct, fromGarments };
}
