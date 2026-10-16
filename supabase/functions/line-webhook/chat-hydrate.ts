/** The wardrobe read is bound to `userId`; the catalog is public, a wardrobe is not. */
import type { AnswerHydrator } from "../_shared/chat/index.ts";
import { idsOf } from "../_shared/chat/hydrate.ts";
import { fetchProductRows } from "./product-card.ts";
import { fetchWardrobeRows } from "./wardrobe-card.ts";

export function makeLineAnswerRows(imagesBaseUrl: string): AnswerHydrator {
  return async (admin, userId, blocks) => {
    const [products, wardrobe] = await Promise.all([
      fetchProductRows(admin, idsOf(blocks, "product"), imagesBaseUrl),
      fetchWardrobeRows(admin, userId, idsOf(blocks, "wardrobe")),
    ]);
    return { products, wardrobe };
  };
}
