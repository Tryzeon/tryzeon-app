import { ValidationError } from "./errors.ts";
import type { GenerationLog } from "./types.ts";
import type { DbClient } from "../supabase.ts";

const TRYON_GENERATIONS_TABLE = "tryon_generations";
const UNIQUE_VIOLATION = "23505";

export const supabaseGenerationLog = (admin: DbClient): GenerationLog => ({
  async start({ id, userId, mode }) {
    const { data, error } = await admin
      .from(TRYON_GENERATIONS_TABLE)
      .insert({ ...(id && { id }), user_id: userId, mode })
      .select("id")
      .single();
    if (error?.code === UNIQUE_VIOLATION) {
      throw new ValidationError("generationId already used");
    }
    if (error) {
      throw new Error(`Failed to start try-on generation: ${error.message}`);
    }
    return data.id;
  },

  async succeed(id, resultKey) {
    const { error } = await admin
      .from(TRYON_GENERATIONS_TABLE)
      .update({
        status: "succeeded",
        result_key: resultKey,
        completed_at: new Date().toISOString(),
      })
      .eq("id", id);
    if (error) {
      throw new Error(`Failed to complete try-on generation: ${error.message}`);
    }
  },

  async fail(id, errorMessage) {
    const { error } = await admin
      .from(TRYON_GENERATIONS_TABLE)
      .update({
        status: "failed",
        error_message: errorMessage,
        completed_at: new Date().toISOString(),
      })
      .eq("id", id);
    if (error) {
      throw new Error(`Failed to fail try-on generation: ${error.message}`);
    }
  },
});
