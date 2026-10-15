export type WireBlock = Record<string, unknown>;

export interface WireMessage {
  role: "user" | "assistant";
  content: WireBlock[];
}

/** Render data for the answer's item refs, keyed by id; never sent back. */
export interface WireItems {
  products: Record<string, unknown>;
  wardrobe: Record<string, unknown>;
}

/**
 * `tool_use` and `tool_result` lines are progress only, which this client does
 * not show: the turn arrives whole as `messages` on `done`, to be stored as is.
 */
export type ChatEvent =
  | { type: "done"; messages: WireMessage[]; items: WireItems }
  | { type: "error"; code: string };

export const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

const isWireMessage = (v: unknown): v is WireMessage =>
  isRecord(v) && (v.role === "user" || v.role === "assistant") &&
  Array.isArray(v.content) && v.content.every(isRecord);

export function userText(text: string): WireMessage {
  return { role: "user", content: [{ type: "text", text }] };
}

export function parseChatLine(line: string): ChatEvent | null {
  const trimmed = line.trim();
  if (trimmed.length === 0) return null;

  let raw: unknown;
  try {
    raw = JSON.parse(trimmed);
  } catch {
    console.warn("[chat] unparseable stream line:", trimmed);
    return null;
  }
  if (!isRecord(raw)) return null;

  switch (raw.type) {
    case "done": {
      const messages = Array.isArray(raw.messages) ? raw.messages.filter(isWireMessage) : [];
      const items = isRecord(raw.items) ? raw.items : {};
      return {
        type: "done",
        messages,
        items: {
          products: isRecord(items.products) ? items.products : {},
          wardrobe: isRecord(items.wardrobe) ? items.wardrobe : {},
        },
      };
    }
    case "error":
      return { type: "error", code: typeof raw.code === "string" ? raw.code : "INTERNAL_ERROR" };
    default:
      return null;
  }
}
