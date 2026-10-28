import type { TryonRecorder } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export const supabaseTryonRecorder =
  (admin: DbClient): TryonRecorder => async (userId, worn) => {
    const { error } = await admin.rpc("log_tryon_events", {
      p_user_id: userId,
      p_worn: worn.map((w) => ({
        product_id: w.productId,
        color_id: w.colorId,
      })),
    });
    if (error) {
      throw new Error(`Failed to log try-on events: ${error.message}`);
    }
  };
