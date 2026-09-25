import { supabase } from "../lib/supabase";
import { toApiError } from "./errors";
import { type ChatEvent, parseChatLine, type WireMessage } from "./chat-wire";

/**
 * Waits for the whole NDJSON body instead of reading it as a stream: the answer
 * only arrives with the final `done` event, so streaming would buy nothing but a
 * progress label. supabase-js hands an `application/x-ndjson` body back as text.
 */
export async function sendChat(messages: WireMessage[]): Promise<ChatEvent[]> {
  const { data, error } = await supabase.functions.invoke("chat", { body: { messages } });
  if (error) throw toApiError(error);
  if (typeof data !== "string") throw new Error("chat response was not text");

  return data
    .split("\n")
    .map(parseChatLine)
    .filter((event): event is ChatEvent => event !== null);
}
