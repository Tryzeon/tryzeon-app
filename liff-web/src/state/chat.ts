import type { CatalogItem } from "../api/catalog-row";
import {
  type ChatEvent,
  isRecord,
  userText,
  type WireBlock,
  type WireItems,
  type WireMessage,
} from "../api/chat-wire";

export type ResolvedItem =
  | { kind: "product"; item: CatalogItem }
  | { kind: "wardrobe"; id: string; imagePath: string; garmentType: string | null; tags: string[] };

export interface ResolvedPick {
  item: ResolvedItem;
  highlight?: string;
}

export interface ResolvedOutfit {
  title: string;
  reason?: string;
  pieces: ResolvedItem[];
}

export type ChatEntry =
  | { kind: "user"; text: string }
  | { kind: "text"; text: string }
  | { kind: "picks"; picks: ResolvedPick[] }
  | { kind: "outfits"; outfits: ResolvedOutfit[] }
  | { kind: "notice"; text: string };

/**
 * `turn` is the user's message still awaiting an answer. It joins `history`,
 * followed by the messages `done` brings, only once they arrive; a failed turn
 * is dropped whole, because the next request would otherwise replay a question
 * the model reads as ignored.
 */
export interface ChatState {
  history: WireMessage[];
  turn: WireMessage | null;
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

const RATE_LIMIT_TEXT = "今天聊得比較多了，休息一下再來找我。";
const FAILURE_TEXT = "出了點狀況，請稍後再試。";
const EMPTY_ANSWER_TEXT = "抱歉，我沒有理解，可以再說一次你的需求嗎？";

function fail(state: ChatState, code: string): ChatState {
  if (state.turn === null) return state;
  const text = code === "RATE_LIMIT_EXCEEDED" ? RATE_LIMIT_TEXT : FAILURE_TEXT;
  return { ...state, turn: null, entries: [...state.entries, { kind: "notice", text }] };
}

export function createChatReducer(toItem: (row: unknown) => CatalogItem) {
  const str = (value: unknown): string | undefined => (typeof value === "string" ? value : undefined);

  function resolveItem(ref: unknown, items: WireItems): ResolvedItem | null {
    if (!isRecord(ref)) return null;
    const id = String(ref.id);
    if (ref.type === "product") {
      const row = items.products[id];
      if (!isRecord(row)) return null;
      return { kind: "product", item: toItem(row) };
    }
    if (ref.type === "wardrobe") {
      const row = items.wardrobe[id];
      if (!isRecord(row)) return null;
      const imagePath = row.image_path;
      if (typeof imagePath !== "string" || imagePath.length === 0) return null;
      return {
        kind: "wardrobe",
        id,
        imagePath,
        garmentType: typeof row.garment_type === "string" ? row.garment_type : null,
        tags: Array.isArray(row.tags)
          ? row.tags.filter((t): t is string => typeof t === "string" && t.length > 0)
          : [],
      };
    }
    return null;
  }

  function resolvePicks(block: WireBlock, items: WireItems): ResolvedPick[] {
    const picks: ResolvedPick[] = [];
    for (const raw of Array.isArray(block.picks) ? block.picks : []) {
      const item = resolveItem(raw, items);
      if (item === null) continue;
      const highlight = isRecord(raw) ? str(raw.highlight) : undefined;
      picks.push({ item, ...(highlight === undefined ? {} : { highlight }) });
    }
    return picks;
  }

  /** A look missing a piece is not the look that was put together, so it is left out whole. */
  function resolveOutfits(block: WireBlock, items: WireItems): ResolvedOutfit[] {
    const looks: ResolvedOutfit[] = [];
    for (const raw of Array.isArray(block.outfits) ? block.outfits : []) {
      if (!isRecord(raw)) continue;
      const title = str(raw.title);
      const refs = Array.isArray(raw.pieces) ? raw.pieces : [];
      const pieces = refs.map((ref) => resolveItem(ref, items));
      if (title === undefined || pieces.some((piece) => piece === null)) continue;
      const reason = str(raw.reason);
      looks.push({ title, ...(reason === undefined ? {} : { reason }), pieces: pieces as ResolvedItem[] });
    }
    return looks;
  }

  function answerEntries(answer: WireMessage | undefined, items: WireItems): ChatEntry[] {
    const entries: ChatEntry[] = [];
    for (const block of answer?.content ?? []) {
      if (block.type === "text" && typeof block.text === "string") {
        entries.push({ kind: "text", text: block.text });
      } else if (block.type === "picks") {
        const picks = resolvePicks(block, items);
        if (picks.length > 0) entries.push({ kind: "picks", picks });
      } else if (block.type === "outfits") {
        const outfits = resolveOutfits(block, items);
        if (outfits.length > 0) entries.push({ kind: "outfits", outfits });
      }
    }
    return entries.length > 0 ? entries : [{ kind: "notice", text: EMPTY_ANSWER_TEXT }];
  }

  function onEvent(state: ChatState, event: ChatEvent): ChatState {
    if (state.turn === null) return state;
    switch (event.type) {
      case "done":
        return {
          history: trimHistory([...state.history, state.turn, ...event.messages], HISTORY_LIMIT),
          turn: null,
          entries: [...state.entries, ...answerEntries(event.messages[event.messages.length - 1], event.items)],
        };
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
          turn: userText(action.text),
          entries: [...state.entries, { kind: "user", text: action.text }],
        };
      case "event":
        return onEvent(state, action.event);
      case "ended":
        return fail(state, "INTERNAL_ERROR");
    }
  };
}
