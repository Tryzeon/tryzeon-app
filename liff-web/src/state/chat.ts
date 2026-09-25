import type { CatalogItem } from "../api/catalog-row";
import {
  type ChatEvent,
  dehydrateBlock,
  userText,
  type WireBlock,
  type WireMessage,
} from "../api/chat-wire";

export type ChatEntry =
  | { kind: "user"; text: string }
  | { kind: "text"; text: string }
  | { kind: "product"; item: CatalogItem }
  | { kind: "wardrobe"; imagePath: string }
  | { kind: "notice"; text: string };

/**
 * `turn` is the exchange still in flight — the user's message and its tool
 * rounds. It joins `history` only once an answer arrives; a failed turn is
 * dropped whole, because the next request would otherwise replay a question
 * the model reads as ignored.
 */
export interface ChatState {
  history: WireMessage[];
  turn: WireMessage[] | null;
  entries: ChatEntry[];
}

export type ChatAction =
  | { type: "send"; text: string }
  | { type: "event"; event: ChatEvent }
  | { type: "ended" };

export const initialChatState: ChatState = { history: [], turn: null, entries: [] };

/**
 * The server rejects a request over 400 messages (`LIMITS.MAX_MESSAGES`) and a
 * single turn can add twenty, so the replayed history is kept well under it —
 * which also bounds what every request costs in tokens.
 */
export const HISTORY_LIMIT = 200;

const isTurnStart = (m: WireMessage): boolean =>
  m.role === "user" && m.content.some((b) => b.type === "text");

/** Cuts only at a user question, so a tool_result never loses its tool_use. */
export function trimHistory(history: WireMessage[], limit: number): WireMessage[] {
  if (history.length <= limit) return history;
  for (let start = history.length - limit; start < history.length; start++) {
    if (isTurnStart(history[start])) return history.slice(start);
  }
  return [];
}

const RATE_LIMIT_TEXT = "今天的對話次數已用完，明天再來聊。";
const FAILURE_TEXT = "出了點狀況，請稍後再試。";
const EMPTY_ANSWER_TEXT = "抱歉，我沒有理解，可以再說一次你的需求嗎？";

function fail(state: ChatState, code: string): ChatState {
  if (state.turn === null) return state;
  const text = code === "RATE_LIMIT_EXCEEDED" ? RATE_LIMIT_TEXT : FAILURE_TEXT;
  return { ...state, turn: null, entries: [...state.entries, { kind: "notice", text }] };
}

export function createChatReducer(toItem: (row: unknown) => CatalogItem) {
  function answerEntries(blocks: WireBlock[]): ChatEntry[] {
    const entries: ChatEntry[] = [];
    for (const block of blocks) {
      if (block.type === "text" && typeof block.text === "string" && block.text.trim().length > 0) {
        entries.push({ kind: "text", text: block.text });
      } else if (block.type === "product" && typeof block.item === "object" && block.item !== null) {
        entries.push({ kind: "product", item: toItem(block.item) });
      } else if (block.type === "wardrobe" && typeof block.item === "object" && block.item !== null) {
        const imagePath = (block.item as Record<string, unknown>).image_path;
        if (typeof imagePath === "string" && imagePath.length > 0) {
          entries.push({ kind: "wardrobe", imagePath });
        }
      }
    }
    return entries.length > 0 ? entries : [{ kind: "notice", text: EMPTY_ANSWER_TEXT }];
  }

  function onEvent(state: ChatState, event: ChatEvent): ChatState {
    if (state.turn === null) return state;
    switch (event.type) {
      case "tool_use":
        return { ...state, turn: [...state.turn, { role: "assistant", content: [event.block] }] };
      case "tool_result":
        return { ...state, turn: [...state.turn, { role: "user", content: [event.block] }] };
      case "done": {
        const answer: WireMessage = {
          role: "assistant",
          content: event.blocks
            .map(dehydrateBlock)
            .filter((b): b is WireBlock => b !== null),
        };
        return {
          history: trimHistory([...state.history, ...state.turn, answer], HISTORY_LIMIT),
          turn: null,
          entries: [...state.entries, ...answerEntries(event.blocks)],
        };
      }
      case "error":
        return fail(state, event.code);
    }
  }

  return function chatReducer(state: ChatState, action: ChatAction): ChatState {
    switch (action.type) {
      case "send":
        if (state.turn !== null) return state;
        return {
          ...state,
          turn: [userText(action.text)],
          entries: [...state.entries, { kind: "user", text: action.text }],
        };
      case "event":
        return onEvent(state, action.event);
      case "ended":
        return fail(state, "INTERNAL_ERROR");
    }
  };
}
