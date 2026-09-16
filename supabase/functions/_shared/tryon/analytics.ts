import type { TryonRecorder } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export const supabaseTryonRecorder =
  (admin: DbClient): TryonRecorder => async (userId, productIds) => {
    const { error } = await admin.rpc("log_tryon_events", {
      p_user_id: userId,
      p_product_ids: productIds,
    });
    if (error) {
      throw new Error(`Failed to log try-on events: ${error.message}`);
    }
  };
