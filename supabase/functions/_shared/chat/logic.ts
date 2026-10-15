// Pure helpers for the chat agent loop. No runtime SDK or network imports, so
// they unit-test offline.
import { isUuid, nonEmptyStr } from "../text.ts";
import { asRecord } from "../validation.ts";
import {
  CHANNEL_VALUES,
  ELASTICITY_VALUES,
  FIT_VALUES,
  GENDER_VALUES,
  SEASON_VALUES,
  THICKNESS_VALUES,
} from "../vocabularies.ts";
import { LIMITS } from "./types.ts";
import type {
  JSONValue,
  ModelMessage,
  TextPart,
  TextStreamPart,
  ToolCallPart,
  ToolSet,
} from "ai";
import type { Database } from "../database.types.ts";
import type {
  AnswerItems,
  AnswerRef,
  AnswerRows,
  ChatEvent,
  ChatMessage,
  ContentBlock,
  ItemRef,
} from "./types.ts";

export const SEARCH_LIMIT = 10;

export const WARDROBE_SELECT = "id, image_path, garment_type, tags, created_at, updated_at";

// Shop product shape for an answer card — mirrors the product detail page so the
// client renders it directly (sizes + the owning store's public fields).
export const PRODUCT_SELECT =
  "*, product_sizes(*), store_profiles!products_store_id_fkey(id, name, address, logo_path, channels)";

type Enums = Database["public"]["Enums"];
type ListShopProductsArgs = Database["public"]["Functions"]["list_shop_products"]["Args"];

const nonEmptyStringArray = (v: unknown): string[] | undefined =>
  Array.isArray(v) && v.length > 0 ? v.map(String) : undefined;

function isInVocabulary<T extends string>(value: unknown, vocab: readonly T[]): value is T {
  return typeof value === "string" && (vocab as readonly string[]).includes(value);
}

const vocabularyError = (field: string, bad: unknown, vocab: readonly string[]): string =>
  `${field} 參數包含不支援的值「${String(bad)}」。請改用允許的值（${
    vocab.join("、")
  }）其中之一，或省略 ${field} 參數後重試。`;

// Enum-backed filters the model chooses values for. p_fits/p_seasons/p_elasticities/
// p_thicknesses/p_channels/p_gender are Postgres enum (array) parameters: an
// invented value is a cast error, not a filter that matches nothing, so — same
// principle as resolveCategoryFilter below — a value outside the vocabulary is
// rejected rather than silently dropped. Dropping only the bad entries out of a
// mixed list would still run a query the model believes is fully filtered; the
// whole field is rejected unless every value in it is in vocabulary.
function readVocabularyArray<T extends string>(
  value: unknown,
  field: string,
  vocab: readonly T[],
): { ok: true; values?: T[] } | { ok: false; error: string } {
  if (!Array.isArray(value) || value.length === 0) return { ok: true };
  const values: T[] = [];
  for (const entry of value) {
    if (!isInVocabulary(entry, vocab)) {
      return { ok: false, error: vocabularyError(field, entry, vocab) };
    }
    values.push(entry);
  }
  return { ok: true, values };
}

export interface VocabularyFilters {
  channels?: Enums["store_channel"][];
  elasticities?: Enums["product_elasticity"][];
  fits?: Enums["product_fit"][];
  seasons?: Enums["product_season"][];
  thicknesses?: Enums["product_thickness"][];
  gender?: Enums["product_gender"];
}

export type VocabularyFilter =
  | { ok: true; filters: VocabularyFilters }
  | { ok: false; error: string };

export function validateVocabularyFilters(args: Record<string, unknown>): VocabularyFilter {
  const fits = readVocabularyArray(args.fits, "fits", FIT_VALUES);
  if (!fits.ok) return fits;
  const seasons = readVocabularyArray(args.seasons, "seasons", SEASON_VALUES);
  if (!seasons.ok) return seasons;
  const elasticities = readVocabularyArray(args.elasticities, "elasticities", ELASTICITY_VALUES);
  if (!elasticities.ok) return elasticities;
  const thicknesses = readVocabularyArray(args.thicknesses, "thicknesses", THICKNESS_VALUES);
  if (!thicknesses.ok) return thicknesses;
  const channels = readVocabularyArray(args.channels, "channels", CHANNEL_VALUES);
  if (!channels.ok) return channels;

  const gender = args.gender;
  const hasGender = gender !== undefined && gender !== null;
  if (hasGender && !isInVocabulary(gender, GENDER_VALUES)) {
    return { ok: false, error: vocabularyError("gender", gender, GENDER_VALUES) };
  }

  return {
    ok: true,
    filters: {
      fits: fits.values,
      seasons: seasons.values,
      elasticities: elasticities.values,
      thicknesses: thicknesses.values,
      channels: channels.values,
      gender: hasGender ? gender : undefined,
    },
  };
}

// Resolve the model's category_code into the id filter the RPC takes. An absent
// code means "no category filter"; an unrecognised one is rejected rather than
// silently dropped — dropping it would run an unfiltered search and hand the
// model cross-category products it believes are filtered.
export type CategoryFilter =
  | { ok: true; categoryIds: string[] | null }
  | { ok: false; error: string };

export function resolveCategoryFilter(
  rawCode: unknown,
  categoryIdByCode: Map<string, string>,
): CategoryFilter {
  const code = nonEmptyStr(rawCode);
  if (code === null) return { ok: true, categoryIds: null };

  const id = categoryIdByCode.get(code);
  if (id === undefined) {
    return {
      ok: false,
      error:
        `未知的分類 code「${code}」。請改用【可用商品分類清單】中的 code，或省略 category_code 後重試。`,
    };
  }
  return { ok: true, categoryIds: [id] };
}

// gender is an optional model-chosen filter, not a forced one — the model
// decides whether to apply it, informed by the user context in the prompt.
// Absent filters are omitted rather than sent as null; every parameter defaults
// to NULL in SQL, so the two mean the same thing to the RPC.
export function mapSearchProductsArgs(
  args: Record<string, unknown>,
  opts: { categoryIds: string[] | null; filters: VocabularyFilters },
): ListShopProductsArgs {
  const { filters } = opts;
  return {
    p_search_query: nonEmptyStr(args.query) ?? undefined,
    p_category_ids: opts.categoryIds && opts.categoryIds.length > 0
      ? opts.categoryIds
      : undefined,
    p_min_price: typeof args.min_price === "number" ? args.min_price : undefined,
    p_max_price: typeof args.max_price === "number" ? args.max_price : undefined,
    p_channels: filters.channels,
    p_gender: filters.gender,
    p_materials: nonEmptyStringArray(args.materials),
    p_elasticities: filters.elasticities,
    p_fits: filters.fits,
    p_thicknesses: filters.thicknesses,
    p_styles: nonEmptyStringArray(args.styles),
    p_seasons: filters.seasons,
    p_sort_column: "created_at",
    p_sort_ascending: false,
    p_limit: SEARCH_LIMIT,
    p_offset: 0,
  };
}

// An attribute the shop left unset and one that does not exist are the same
// fact to the model, and only the first costs tokens — so only set fields ship.
const withSetFields = (o: Record<string, unknown>): Record<string, unknown> =>
  Object.fromEntries(
    Object.entries(o).filter(([, v]) =>
      v !== null && v !== undefined && !(Array.isArray(v) && v.length === 0)
    ),
  );


export function toSearchResultItem(row: Record<string, unknown>): Record<string, unknown> {
  const store = (row.store_profiles ?? null) as Record<string, unknown> | null;
  const variants = Array.isArray(row.product_variants) ? row.product_variants : [];

  return withSetFields({
    id: String(row.id),
    name: row.name,
    price: row.price,
    store: store?.name ?? null,
    channels: store?.channels ?? null,
    sizes: variants.map((v) => asRecord(v)?.name).filter(Boolean),
    gender: row.gender,
    material: row.material,
    fit: row.fit,
    elasticity: row.elasticity,
    thickness: row.thickness,
    styles: row.styles,
    seasons: row.seasons,
  });
}

const isTurnStart = (m: ChatMessage): boolean =>
  m.role === "user" && !m.content.some((b) => b?.type === "tool_result");

// Drops the oldest whole turns until at most `max` messages remain. The cut
// lands only on a turn start, so no tool_result outlives the tool_use it
// answers. Empty when the tail holds no turn start at all.
export function windowHistory(
  messages: ChatMessage[],
  max: number = LIMITS.MAX_MESSAGES,
): ChatMessage[] {
  if (messages.length <= max) return messages;
  const tail = messages.slice(-max);
  const start = tail.findIndex(isTurnStart);
  return start === -1 ? [] : tail.slice(start);
}

export const TOOL_FAILURE_TEXT = "工具執行失敗，沒有取得結果。";

/**
 * Turns the agent loop's stream into the transcript it adds: per finished step,
 * one assistant message with every call the model made in it, then one user
 * message with their results — the shape the model answered in, so a replay
 * hands it back the turn it actually took. Each call is reported to `onEvent`
 * as it streams, each result as it lands.
 *
 * A failed call is answered with an error result, so no call is replayed
 * without one. A step the stream never finished is left out.
 *
 * Gemini's thought signatures are not kept: they would ride through every
 * client as opaque provider state, and only the current turn's are validated,
 * which the SDK holds itself. On replay it stands in a placeholder for the
 * missing ones and logs a warning saying so.
 */
export async function recordRounds(
  stream: AsyncIterable<TextStreamPart<ToolSet>>,
  onEvent?: (ev: ChatEvent) => void,
): Promise<ChatMessage[]> {
  const rounds: ChatMessage[] = [];
  let calls: ContentBlock[] = [];
  let results: ContentBlock[] = [];

  const answer = (toolUseId: string, content: unknown) => {
    const event: ChatEvent = { type: "tool_result", tool_use_id: toolUseId, content };
    results.push(event);
    onEvent?.(event);
  };

  for await (const part of stream) {
    switch (part.type) {
      case "tool-call": {
        const event: ChatEvent = {
          type: "tool_use",
          id: part.toolCallId,
          name: part.toolName,
          input: part.input,
        };
        calls.push(event);
        onEvent?.(event);
        break;
      }
      case "tool-result":
        answer(part.toolCallId, part.output);
        break;
      case "tool-error":
        answer(part.toolCallId, { error: TOOL_FAILURE_TEXT });
        break;
      case "finish-step":
        if (calls.length > 0) {
          rounds.push({ role: "assistant", content: calls }, { role: "user", content: results });
        }
        calls = [];
        results = [];
        break;
    }
  }
  return rounds;
}

export function recommendedItems(block: ContentBlock): ItemRef[] {
  if (block?.type !== "recommendation" || !Array.isArray(block.items)) return [];
  const refs: ItemRef[] = [];
  for (const entry of block.items) {
    const item = asRecord(entry);
    const type = item?.type;
    const id = nonEmptyStr(item?.id);
    if ((type === "product" || type === "wardrobe") && id !== null) refs.push({ type, id });
  }
  return refs;
}

const replayName = ({ type, id }: ItemRef): string =>
  `${type === "product" ? "商品" : "衣櫃單品"} id:${id}`;

// The whole history is replayed verbatim and uncompressed: assistant tool_use →
// a `tool-call` part, the paired user tool_result → a `tool` message with a
// `tool-result` part (its tool name resolved from the tool_use id), text passes
// through. A recommended row is named by its items' ids alone: their full data
// is already replayed in the tool_result.
export function toModelMessages(messages: ChatMessage[]): ModelMessage[] {
  const nameOf = new Map<string, string>();
  for (const m of messages ?? []) {
    if (m?.role !== "assistant") continue;
    for (const b of Array.isArray(m.content) ? m.content : []) {
      if (b?.type === "tool_use" && b.id && b.name) nameOf.set(String(b.id), String(b.name));
    }
  }

  const out: ModelMessage[] = [];
  for (const m of messages ?? []) {
    const blocks = Array.isArray(m?.content) ? m.content : [];

    if (m?.role === "user") {
      const toolResults = blocks.filter((b) => b?.type === "tool_result");
      if (toolResults.length) {
        out.push({
          role: "tool",
          content: toolResults.map((b) => ({
            type: "tool-result",
            toolCallId: String(b.tool_use_id),
            toolName: nameOf.get(String(b.tool_use_id)) ?? "unknown",
            output: { type: "json", value: (b.content ?? {}) as JSONValue },
          })),
        });
      }
      const text = blocks
        .filter((b) => b?.type === "text")
        .map((b) => nonEmptyStr(b.text))
        .filter((t): t is string => t !== null)
        .join("\n");
      if (text) out.push({ role: "user", content: text });
      continue;
    }

    // assistant
    const toolUses = blocks.filter((b) => b?.type === "tool_use" && b.name);
    const lines: string[] = [];
    for (const b of blocks) {
      const t = b?.type === "text" ? nonEmptyStr(b.text) : null;
      if (t) lines.push(t);
      else if (b?.type === "recommendation") {
        const named = recommendedItems(b).map(replayName);
        if (named.length > 0) lines.push(`（推薦：${named.join("、")}）`);
      }
    }
    const text = lines.join("\n").trim();

    if (toolUses.length) {
      const content: Array<TextPart | ToolCallPart> = [];
      if (text) content.push({ type: "text", text });
      for (const b of toolUses) {
        content.push({
          type: "tool-call",
          toolCallId: String(b.id),
          toolName: String(b.name),
          input: b.input ?? {},
        });
      }
      out.push({ role: "assistant", content });
    } else if (text) {
      out.push({ role: "assistant", content: text });
    }
  }
  return out;
}

// The model groups its picks into rows (one recommendation per row) and labels
// each item product = shop or wardrobe = wardrobe; the edge fetches each id from
// the matching table. Empty text, bad items and rows left empty drop, and an
// item repeated within its row is kept once.
//
// So does an item whose id is not a uuid. The model quotes ids back from tool
// results and can misquote one — a dropped character is enough — and every id
// here is spent as a uuid literal in the hydrator's `.in("id", ids)`, where
// Postgres rejects the malformed one by failing the whole batch (22P02). That
// would cost the caller the answer, valid ids and all, so the check belongs to
// the parse: an id that cannot name a row is a bad item, and the parse drops those.
export function parseAnswerRefs(args: Record<string, unknown>): AnswerRef[] {
  const rawBlocks = Array.isArray(args?.blocks) ? args.blocks : [];
  const refs: AnswerRef[] = [];
  for (const raw of rawBlocks) {
    const b = asRecord(raw);
    if (b === null) continue;
    if (b.type === "recommendation") {
      const seen = new Set<string>();
      const items = recommendedItems(b).filter(({ type, id }) => {
        const key = `${type}:${id}`;
        if (!isUuid(id) || seen.has(key)) return false;
        seen.add(key);
        return true;
      });
      if (items.length > 0) refs.push({ type: "recommendation", items });
    } else if (b.type === "text") {
      const text = nonEmptyStr(b.text);
      if (text) refs.push({ type: "text", text });
    }
  }
  return refs;
}

/**
 * The answer as it is stored — rows of item refs by id, in the model's order —
 * and the rows those ids render as. An item whose row is gone is dropped from
 * both, and a recommendation left with no items is dropped whole, so the model
 * is never told it recommended something the user did not see.
 */
export function assembleAnswer(
  refs: AnswerRef[],
  rows: AnswerRows,
): { content: ContentBlock[]; items: AnswerItems } {
  const content: ContentBlock[] = [];
  const items: AnswerItems = { products: {}, wardrobe: {} };
  for (const ref of refs) {
    if (ref.type === "text") {
      content.push({ type: "text", text: ref.text });
      continue;
    }
    const kept: ItemRef[] = [];
    for (const item of ref.items) {
      const row = (item.type === "product" ? rows.products : rows.wardrobe).get(item.id);
      if (row === undefined) continue;
      kept.push(item);
      (item.type === "product" ? items.products : items.wardrobe)[item.id] = row;
    }
    if (kept.length > 0) content.push({ type: "recommendation", items: kept });
  }
  return { content, items };
}
