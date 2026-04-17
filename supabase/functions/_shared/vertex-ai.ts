import { GoogleGenAI } from "npm:@google/genai";

export const VERTEX_CONFIG = {
  CHAT_MODEL: Deno.env.get("CHAT_MODEL"),
};

let _aiClient: GoogleGenAI | null = null;

export function getAIClient(): GoogleGenAI {
  if (!_aiClient) {
    const apiKey = Deno.env.get("VERTEX_API_KEY");
    const project = Deno.env.get("GOOGLE_CLOUD_PROJECT");
    const location = Deno.env.get("GOOGLE_CLOUD_LOCATION") || "us-central1";

    if (!apiKey) {
      throw new Error("VERTEX_API_KEY environment variable is required");
    }

    if (!project) {
      throw new Error("GOOGLE_CLOUD_PROJECT environment variable is required");
    }

    _aiClient = new GoogleGenAI({
      apiKey: apiKey,
      vertexai: {
        project: project,
        location: location,
      },
    });
  }

  return _aiClient;
}
