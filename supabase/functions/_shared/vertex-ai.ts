import { GoogleGenAI } from "npm:@google/genai";

export const VERTEX_CONFIG = {
  API_KEY: Deno.env.get("VERTEX_API_KEY"),
  CHAT_MODEL: Deno.env.get("CHAT_MODEL"),
  TRYON_MODEL: Deno.env.get("TRYON_MODEL"),
  VIDEO_MODEL: Deno.env.get("VIDEO_MODEL"),
};

let _aiClient: GoogleGenAI | null = null;

/**
 * Vertex AI Express Mode client using a server-side API key.
 */
export function getAIClient(): GoogleGenAI {
  if (!_aiClient) {
    _aiClient = new GoogleGenAI({
      apiKey: Deno.env.get("VERTEX_API_KEY")!,
      vertexai: true,
    });
  }

  return _aiClient;
}
