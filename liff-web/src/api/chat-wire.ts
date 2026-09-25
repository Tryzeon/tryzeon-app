export type WireBlock = Record<string, unknown>;

export interface WireMessage {
  role: "user" | "assistant";
  content: WireBlock[];
}

export type ChatEvent =
  | { type: "tool_use"; block: WireBlock }
  | { type: "tool_result"; block: WireBlock }
  | { type: "done"; blocks: WireBlock[] }
  | { type: "error"; code: string };

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

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
    case "tool_use":
      return {
        type: "tool_use",
        block: { type: "tool_use", id: raw.id, name: raw.name, input: raw.input ?? {} },
      };
    case "tool_result":
      return {
        type: "tool_result",
        block: { type: "tool_result", tool_use_id: raw.tool_use_id, content: raw.content ?? {} },
      };
    case "done": {
      const content = isRecord(raw.message) && Array.isArray(raw.message.content)
        ? raw.message.content.filter(isRecord)
        : [];
      return { type: "done", blocks: content };
    }
    case "error":
      return { type: "error", code: typeof raw.code === "string" ? raw.code : "INTERNAL_ERROR" };
    default:
      return null;
  }
}

/** The full product row is already replayed in the paired tool_result, so the model needs only the id back. */
export function dehydrateBlock(block: WireBlock): WireBlock | null {
  if (block.type !== "product" && block.type !== "wardrobe") return block;
  const id = isRecord(block.item) ? block.item.id : undefined;
  return typeof id === "string" && id.length > 0 ? { type: block.type, id } : null;
}
