import type { DbClient } from "../supabase.ts";

/**
 * The conversation schema, shared by client storage, the wire (both
 * directions), and rendering. Standard chat-API shape: only user/assistant
 * roles, each a list of content blocks. A tool round spans messages — the
 * `tool_use` blocks of one agent step in an assistant message, paired (by id)
 * with their `tool_result` blocks in the next user message.
 */
export type ContentBlock = Record<string, unknown>;
export type ChatMessage = { role: ChatRole; content: ContentBlock[] };

export type ChatRole = "user" | "assistant";

export type ItemRef = { type: "product" | "wardrobe"; id: string };

export type PickRef = ItemRef & { highlight?: string };

/** Rendered, and tried on, only whole: a look missing a piece is not the look the model put together. */
export type OutfitRef = { title: string; reason?: string; pieces: ItemRef[] };

/** An answer row as stored and sent: read whole by `answerBlocksOf`, so no surface re-checks it. */
export type AnswerBlock =
  | { type: "text"; text: string }
  | { type: "picks"; picks: PickRef[] }
  | { type: "outfits"; outfits: OutfitRef[] };

export type ChatEvent =
  | { type: "tool_use"; id: string; name: string; input: unknown }
  | { type: "tool_result"; tool_use_id: string; content: unknown };

export interface ChatParams {
  userId: string;
  messages: ChatMessage[];
  onEvent?: (ev: ChatEvent) => void;
}

export interface ChatResult {
  /**
   * Every message this run added to the conversation, in order, stored exactly
   * as given: per agent step its calls then their results, and last the answer.
   */
  messages: ChatMessage[];
  /** The last message's blocks, typed for a renderer. */
  answer: AnswerBlock[];
  /** The hydrated rows of every id the answer names; never stored, never sent back. */
  items: AnswerItems;
}

export const LIMITS = {
  /**
   * Window on replayed history: `toModelMessages` replays every turn verbatim,
   * so an unbounded conversation is an unbounded per-request cost. A longer
   * history is not refused — `windowHistory` drops its oldest whole turns, so
   * the conversation keeps working and forgets its beginning. The LINE
   * conversation store saves under the same window.
   */
  MAX_MESSAGES: 400,
  MAX_TEXT_LENGTH: 2000,
} as const;

export interface ChatContext {
  systemInstruction: string;
  categoryIdByCode: Map<string, string>;
}

export type ContextLoader = (
  client: DbClient,
  userId: string,
) => Promise<ChatContext>;

export interface AgentRequest {
  client: DbClient;
  userId: string;
  context: ChatContext;
  messages: ChatMessage[];
  onEvent?: (ev: ChatEvent) => void;
}

export interface AgentAnswer {
  output: Record<string, unknown> | null;
  rounds: ChatMessage[];
}

export type AgentRunner = (req: AgentRequest) => Promise<AgentAnswer>;

/**
 * Read-only and item-typed as `unknown`: an adapter hydrates whatever shape its
 * renderer needs (a db row for the app, a LINE card model for the webhook), and
 * `runChatAgent` only ever passes the item through to `AnswerItems`.
 */
export interface AnswerRows {
  products: ReadonlyMap<string, unknown>;
  wardrobe: ReadonlyMap<string, unknown>;
}

/** Keyed by id, as plain objects so the result goes on the wire unconverted. */
export interface AnswerItems {
  products: Record<string, unknown>;
  wardrobe: Record<string, unknown>;
}

export type AnswerHydrator = (
  client: DbClient,
  userId: string,
  blocks: AnswerBlock[],
) => Promise<AnswerRows>;
