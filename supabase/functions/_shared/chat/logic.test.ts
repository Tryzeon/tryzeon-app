import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  answerBlocksOf,
  mapSearchProductsArgs,
  outfitsOf,
  recordRounds,
  resolveCategoryFilter,
  picksOf,
  SEARCH_LIMIT,
  TOOL_FAILURE_TEXT,
  toModelMessages,
  toSearchResultItem,
  validateVocabularyFilters,
  windowHistory,
} from "./logic.ts";
import type { ChatEvent, ChatMessage } from "./types.ts";
import type { TextStreamPart, ToolSet } from "ai";

const CATEGORIES = new Map([["tops", "cat-1"], ["dresses", "cat-2"]]);

Deno.test("resolveCategoryFilter maps a known code to its id", () => {
  const r = resolveCategoryFilter("tops", CATEGORIES);
  assertEquals(r, { ok: true, categoryIds: ["cat-1"] });
});

Deno.test("resolveCategoryFilter treats a missing code as no category filter", () => {
  assertEquals(resolveCategoryFilter(undefined, CATEGORIES), { ok: true, categoryIds: null });
  assertEquals(resolveCategoryFilter("   ", CATEGORIES), { ok: true, categoryIds: null });
});

Deno.test("resolveCategoryFilter rejects an unknown code instead of dropping the filter", () => {
  const r = resolveCategoryFilter("dress_pants", CATEGORIES);
  assertEquals(r.ok, false);
  if (r.ok) throw new Error("expected a rejection");
  assertStringIncludes(r.error, "dress_pants");
  assertStringIncludes(r.error, "category_code");
});

Deno.test("resolveCategoryFilter does not accept a display name where a code is expected", () => {
  const r = resolveCategoryFilter("上衣", CATEGORIES);
  assertEquals(r.ok, false);
});

Deno.test("mapSearchProductsArgs trims query, keeps non-empty arrays, drops empties", () => {
  const p = mapSearchProductsArgs(
    { query: "  白襯衫 ", styles: ["casual"], materials: [], min_price: 100 },
    { categoryIds: ["c1"], filters: { gender: "female" } },
  );
  assertEquals(p.p_search_query, "白襯衫");
  assertEquals(p.p_styles, ["casual"]);
  assertEquals(p.p_materials, undefined);
  assertEquals(p.p_min_price, 100);
  assertEquals(p.p_category_ids, ["c1"]);
  assertEquals(p.p_gender, "female");
  assertEquals(p.p_limit, SEARCH_LIMIT);
});

Deno.test("mapSearchProductsArgs omits absent filters so the RPC applies its SQL defaults", () => {
  const p = mapSearchProductsArgs({}, { categoryIds: null, filters: {} });
  assertEquals(p.p_search_query, undefined);
  assertEquals(p.p_category_ids, undefined);
  assertEquals(p.p_gender, undefined);
  assertEquals(p.p_limit, SEARCH_LIMIT);
});

Deno.test("mapSearchProductsArgs takes the enum-backed filters from the validated set, not raw args", () => {
  const p = mapSearchProductsArgs(
    { fits: ["tight"], channels: ["carrier-pigeon"] },
    { categoryIds: null, filters: { fits: ["slim"] } },
  );
  assertEquals(p.p_fits, ["slim"]);
  assertEquals(p.p_channels, undefined);
});

type Ref = { type: "product" | "wardrobe"; id: string; highlight?: string };

const picks = (...refs: Ref[]) => ({ type: "picks" as const, picks: refs });
const outfit = (title: string, refs: Ref[], reason?: string) => ({
  title,
  ...(reason === undefined ? {} : { reason }),
  pieces: refs,
});
const outfits = (...looks: ReturnType<typeof outfit>[]) => ({ type: "outfits" as const, outfits: looks });

const p = (id: string, highlight?: string): Ref => ({
  type: "product",
  id,
  ...(highlight === undefined ? {} : { highlight }),
});
const w = (id: string): Ref => ({ type: "wardrobe", id });

Deno.test("picksOf reads a stored row without judging its ids", () => {
  assertEquals(picksOf(picks(p("p1", "顯瘦"), w("w1"))), [p("p1", "顯瘦"), w("w1")]);
});

Deno.test("picksOf trims a highlight, omits a blank one and keeps the first of a repeated item", () => {
  assertEquals(
    picksOf(picks(p("p1", "  顯瘦  "), p("p2", "   "), p("p1", "重複"), w("p1"))),
    [p("p1", "顯瘦"), p("p2"), w("p1")],
  );
});

Deno.test("picksOf reads nothing from a malformed block", () => {
  assertEquals(picksOf({ type: "text", text: "x" }), []);
  assertEquals(picksOf({ type: "picks" }), []);
  assertEquals(picksOf({ type: "picks", picks: "p1" }), []);
  assertEquals(picksOf({ type: "picks", picks: [null, 3, { type: "product" }, { type: "hat", id: "h" }] }), []);
});

Deno.test("outfitsOf reads stored outfits and skips one it cannot read whole", () => {
  assertEquals(
    outfitsOf({
      type: "outfits",
      outfits: [
        outfit("週末休閒", [p("p1"), w("w1")], "白襯衫配深藍直筒"),
        { title: "缺件", pieces: [{ type: "product", id: "p1" }, { type: "hat", id: "h" }] },
        { title: "", pieces: [{ type: "product", id: "p1" }] },
        null,
      ],
    }),
    [outfit("週末休閒", [p("p1"), w("w1")], "白襯衫配深藍直筒")],
  );
  assertEquals(outfitsOf({ type: "picks", picks: [] }), []);
});

Deno.test("outfitsOf counts a repeated piece once, then keeps two or three pieces only", () => {
  const look = (...pieces: Ref[]) => outfit("L", pieces);
  const read = (...pieces: Ref[]) => outfitsOf(outfits(look(...pieces)));
  assertEquals(read(p("p1")), []);
  assertEquals(read(p("p1"), p("p1")), []);
  assertEquals(read(p("p1"), p("p1"), w("w1")), [look(p("p1"), w("w1"))]);
  assertEquals(read(p("p1"), p("p2"), p("p3")), [look(p("p1"), p("p2"), p("p3"))]);
  assertEquals(read(p("p1"), p("p2"), p("p3"), p("p4")), []);
});

Deno.test("outfitsOf skips a blank title and omits a blank reason", () => {
  assertEquals(
    outfitsOf(outfits(
      outfit("   ", [p("p1"), p("p2")], "好看"),
      outfit("  週末  ", [p("p1"), p("p2")], "  "),
      outfit("通勤", [p("p1"), p("p2")], "  理由  "),
    )),
    [outfit("週末", [p("p1"), p("p2")]), outfit("通勤", [p("p1"), p("p2")], "理由")],
  );
});

Deno.test("answerBlocksOf keeps each row as picksOf/outfitsOf read it and drops what reads as nothing", () => {
  assertEquals(
    answerBlocksOf([
      { type: "text", text: "找到這幾件" },
      { type: "text", text: "   " },
      { type: "text" },
      picks(p("p1"), p("p1"), w("w1")),
      { type: "picks", picks: [{ type: "hat", id: "h" }] },
      outfits(outfit("單件", [p("p1")])),
      outfits(outfit("週末", [p("p1"), p("p1"), w("w1")])),
      { type: "tool_use", id: "t0", name: "search_products" },
      null,
      "x",
    ]),
    [
      { type: "text", text: "找到這幾件" },
      picks(p("p1"), w("w1")),
      outfits(outfit("週末", [p("p1"), w("w1")])),
    ],
  );
});

Deno.test("answerBlocksOf reads nothing from a non-array", () => {
  assertEquals(answerBlocksOf(undefined), []);
  assertEquals(answerBlocksOf({ blocks: [] }), []);
});

Deno.test("toModelMessages maps a paired tool_use/tool_result conversation to ModelMessages", () => {
  const answer = [
    { type: "text", text: "找到這幾件" },
    picks(p("p1", "顯瘦"), w("w1")),
    outfits(outfit("週末休閒", [p("p2"), w("w1")], "白襯衫配深藍直筒")),
  ];
  const out = toModelMessages([
    { role: "user", content: [{ type: "text", text: "找裙子" }] },
    {
      role: "assistant",
      content: [{ type: "tool_use", id: "tu_0", name: "search_products", input: { query: "裙" } }],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "tu_0", content: { items: [{ id: "p1" }] } }],
    },
    {
      role: "assistant",
      content: answer,
    },
  ]);
  assertEquals(out, [
    { role: "user", content: "找裙子" },
    {
      role: "assistant",
      content: [{ type: "tool-call", toolCallId: "tu_0", toolName: "search_products", input: { query: "裙" } }],
    },
    {
      role: "tool",
      content: [{
        type: "tool-result",
        toolCallId: "tu_0",
        toolName: "search_products",
        output: { type: "json", value: { items: [{ id: "p1" }] } },
      }],
    },
    {
      role: "assistant",
      content: JSON.stringify({ blocks: answer }),
    },
  ]);
});

Deno.test("toModelMessages replays a final answer verbatim, highlight, reason and title included", () => {
  const blocks = [
    { type: "text", text: "這幾件" },
    picks(p("not-a-uuid", "顯瘦")),
    outfits(outfit("週末休閒", [p("p1"), w("w1")], "白襯衫配深藍直筒")),
  ];
  assertEquals(toModelMessages([{ role: "assistant", content: blocks }]), [
    { role: "assistant", content: JSON.stringify({ blocks }) },
  ]);
});

Deno.test("toModelMessages keeps text beside tool calls as a text part", () => {
  const out = toModelMessages([{
    role: "assistant",
    content: [
      { type: "text", text: "我先找找" },
      { type: "tool_use", id: "tu_0", name: "search_products", input: {} },
    ],
  }]);
  assertEquals(out, [{
    role: "assistant",
    content: [
      { type: "text", text: "我先找找" },
      { type: "tool-call", toolCallId: "tu_0", toolName: "search_products", input: {} },
    ],
  }]);
});

Deno.test("toModelMessages replays a parallel step as one assistant message and one tool message", () => {
  const out = toModelMessages([
    { role: "user", content: [{ type: "text", text: "幫我配這件" }] },
    {
      role: "assistant",
      content: [
        { type: "tool_use", id: "tu_0", name: "search_wardrobe", input: {} },
        { type: "tool_use", id: "tu_1", name: "search_products", input: { query: "褲" } },
      ],
    },
    {
      role: "user",
      content: [
        { type: "tool_result", tool_use_id: "tu_0", content: { items: [] } },
        { type: "tool_result", tool_use_id: "tu_1", content: { items: [] } },
      ],
    },
  ]);
  assertEquals(out, [
    { role: "user", content: "幫我配這件" },
    {
      role: "assistant",
      content: [
        { type: "tool-call", toolCallId: "tu_0", toolName: "search_wardrobe", input: {} },
        { type: "tool-call", toolCallId: "tu_1", toolName: "search_products", input: { query: "褲" } },
      ],
    },
    {
      role: "tool",
      content: [
        {
          type: "tool-result",
          toolCallId: "tu_0",
          toolName: "search_wardrobe",
          output: { type: "json", value: { items: [] } },
        },
        {
          type: "tool-result",
          toolCallId: "tu_1",
          toolName: "search_products",
          output: { type: "json", value: { items: [] } },
        },
      ],
    },
  ]);
});

Deno.test("toModelMessages drops a blank user turn and an empty assistant one", () => {
  const out = toModelMessages([
    { role: "user", content: [{ type: "text", text: "   " }] },
    { role: "assistant", content: [] },
    { role: "assistant", content: [{ type: "text", text: "嗨" }] },
  ]);
  assertEquals(out, [{ role: "assistant", content: JSON.stringify({ blocks: [{ type: "text", text: "嗨" }] }) }]);
});

const SHOP_ROW = {
  id: "8f3a-p1",
  store_id: "11aa-s1",
  name: "白襯衫",
  category_ids: ["cat-1", "cat-2"],
  price: 1200,
  image_paths: ["stores/s1/p1.jpg"],
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-02T00:00:00Z",
  purchase_link: "https://shop.example/p1",
  material: "棉",
  elasticity: "low",
  fit: "regular",
  thickness: null,
  styles: ["minimalist"],
  seasons: [],
  gender: "female",
  product_variants: [
    { id: "v1", product_id: "8f3a-p1", name: "S", created_at: "x", measurements: { chest: 90 } },
    { id: "v2", product_id: "8f3a-p1", name: "M", created_at: "x", measurements: { chest: 94 } },
  ],
  store_profiles: {
    id: "11aa-s1",
    name: "某店",
    address: "台北市…",
    logo_path: "stores/s1/logo.jpg",
    channels: ["online"],
  },
};

Deno.test("toSearchResultItem keeps what the model judges and cites on", () => {
  assertEquals(toSearchResultItem(SHOP_ROW), {
    id: "8f3a-p1",
    name: "白襯衫",
    price: 1200,
    store: "某店",
    channels: ["online"],
    sizes: ["S", "M"],
    gender: "female",
    material: "棉",
    fit: "regular",
    elasticity: "low",
    styles: ["minimalist"],
  });
});

Deno.test("toSearchResultItem ships no uuid but the one the model must copy", () => {
  const item = toSearchResultItem(SHOP_ROW);
  // The whole point of the projection: `store_id`, `category_ids` and each
  // variant's own id are uuids that look exactly like the citable one, and
  // copying the wrong one drops the card with no error raised anywhere.
  for (const key of ["store_id", "category_ids", "product_variants", "store_profiles"]) {
    assertEquals(key in item, false, `${key} must not reach the model`);
  }
  assertStringIncludes(JSON.stringify(item), "8f3a-p1");
  assertEquals(JSON.stringify(item).includes("11aa-s1"), false);
});

Deno.test("toSearchResultItem drops unset attributes rather than sending nulls", () => {
  const item = toSearchResultItem(SHOP_ROW);
  assertEquals("thickness" in item, false);
  assertEquals("seasons" in item, false);
});

Deno.test("toSearchResultItem tolerates a row with no variants and no store", () => {
  const item = toSearchResultItem({ id: "p9", name: "褲", price: 500 });
  assertEquals(item, { id: "p9", name: "褲", price: 500 });
});

Deno.test("validateVocabularyFilters returns the accepted values, typed, rather than a bare pass", () => {
  const r = validateVocabularyFilters({
    fits: ["slim", "regular"],
    seasons: ["summer"],
    elasticities: ["high"],
    thicknesses: ["low"],
    channels: ["online"],
    gender: "female",
  });
  assertEquals(r, {
    ok: true,
    filters: {
      fits: ["slim", "regular"],
      seasons: ["summer"],
      elasticities: ["high"],
      thicknesses: ["low"],
      channels: ["online"],
      gender: "female",
    },
  });
});

Deno.test("validateVocabularyFilters treats absent and empty fields as no filter", () => {
  assertEquals(validateVocabularyFilters({ fits: [] }), {
    ok: true,
    filters: {
      fits: undefined,
      seasons: undefined,
      elasticities: undefined,
      thicknesses: undefined,
      channels: undefined,
      gender: undefined,
    },
  });
});

Deno.test("validateVocabularyFilters rejects a value outside the enum vocabulary instead of dropping it", () => {
  const r = validateVocabularyFilters({ fits: ["tight"] });
  assertEquals(r.ok, false);
  if (r.ok) throw new Error("expected a rejection");
  assertStringIncludes(r.error, "fits");
  assertStringIncludes(r.error, "tight");
});

Deno.test("validateVocabularyFilters rejects gender outside the enum vocabulary", () => {
  const r = validateVocabularyFilters({ gender: "boy" });
  assertEquals(r.ok, false);
  if (r.ok) throw new Error("expected a rejection");
  assertStringIncludes(r.error, "gender");
  assertStringIncludes(r.error, "boy");
});

Deno.test("validateVocabularyFilters rejects a filter mixing valid and invalid values rather than narrowing to the valid ones", () => {
  const r = validateVocabularyFilters({ fits: ["slim", "tight"] });
  assertEquals(r.ok, false);
  if (r.ok) throw new Error("expected a rejection");
  assertStringIncludes(r.error, "tight");
});

const userText = (text: string): ChatMessage => ({
  role: "user",
  content: [{ type: "text", text }],
});

const toolTurn = (n: number): ChatMessage[] => [
  userText(`q${n}`),
  {
    role: "assistant",
    content: [{ type: "tool_use", id: `t${n}`, name: "search_products", input: {} }],
  },
  {
    role: "user",
    content: [{ type: "tool_result", tool_use_id: `t${n}`, content: { items: [] } }],
  },
  { role: "assistant", content: [{ type: "text", text: `a${n}` }] },
];

Deno.test("windowHistory leaves a history within the window untouched", () => {
  const messages = [...toolTurn(1), ...toolTurn(2)];
  assertEquals(windowHistory(messages, 8), messages);
});

Deno.test("windowHistory drops the oldest whole turns, never half a tool round", () => {
  const messages = [...toolTurn(1), ...toolTurn(2), userText("q3")];
  // A cut at 6 would start on turn 1's tool_result, orphaned from its tool_use.
  assertEquals(windowHistory(messages, 6), [...toolTurn(2), userText("q3")]);
});

Deno.test("windowHistory is empty when the window holds no turn start", () => {
  assertEquals(windowHistory(toolTurn(1), 3), []);
});

type StreamPart = TextStreamPart<ToolSet>;

const USAGE_ZERO = {
  inputTokens: 0,
  inputTokenDetails: { noCacheTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0 },
  outputTokens: 0,
  outputTokenDetails: { textTokens: 0, reasoningTokens: 0 },
  totalTokens: 0,
};

const startStep = (): StreamPart => ({
  type: "start-step",
  request: {},
  warnings: [],
});

const finishStep = (finishReason: "tool-calls" | "stop"): StreamPart => ({
  type: "finish-step",
  response: { id: "r", timestamp: new Date(0), modelId: "gemini" },
  usage: USAGE_ZERO,
  finishReason,
  rawFinishReason: undefined,
  providerMetadata: undefined,
} as StreamPart);

const toolCall = (id: string, name: string, signature?: string): StreamPart => ({
  type: "tool-call",
  toolCallId: id,
  toolName: name,
  input: { query: id },
  dynamic: true,
  ...(signature ? { providerMetadata: { vertex: { thoughtSignature: signature } } } : {}),
});

const toolResult = (id: string, name: string): StreamPart => ({
  type: "tool-result",
  toolCallId: id,
  toolName: name,
  input: { query: id },
  output: { items: [{ id: `${id}-item` }] },
  dynamic: true,
});

async function* streamOf(parts: StreamPart[]): AsyncIterable<StreamPart> {
  yield* parts;
}

Deno.test("recordRounds puts a parallel step's calls in one assistant message and their results in one user message", async () => {
  const rounds = await recordRounds(streamOf([
    startStep(),
    toolCall("tu_0", "search_wardrobe", "sig-0"),
    toolCall("tu_1", "search_products"),
    toolResult("tu_1", "search_products"),
    toolResult("tu_0", "search_wardrobe"),
    finishStep("tool-calls"),
    startStep(),
    finishStep("stop"),
  ]));

  assertEquals(rounds, [
    {
      role: "assistant",
      content: [
        { type: "tool_use", id: "tu_0", name: "search_wardrobe", input: { query: "tu_0" } },
        { type: "tool_use", id: "tu_1", name: "search_products", input: { query: "tu_1" } },
      ],
    },
    {
      role: "user",
      content: [
        { type: "tool_result", tool_use_id: "tu_1", content: { items: [{ id: "tu_1-item" }] } },
        { type: "tool_result", tool_use_id: "tu_0", content: { items: [{ id: "tu_0-item" }] } },
      ],
    },
  ]);
});

Deno.test("recordRounds keeps sequential steps as separate rounds", async () => {
  const rounds = await recordRounds(streamOf([
    startStep(),
    toolCall("tu_0", "search_products", "sig-0"),
    toolResult("tu_0", "search_products"),
    finishStep("tool-calls"),
    startStep(),
    toolCall("tu_1", "search_products", "sig-1"),
    toolResult("tu_1", "search_products"),
    finishStep("tool-calls"),
  ]));

  assertEquals(rounds.map((m) => [m.role, m.content.map((b) => b.id ?? b.tool_use_id)]), [
    ["assistant", ["tu_0"]],
    ["user", ["tu_0"]],
    ["assistant", ["tu_1"]],
    ["user", ["tu_1"]],
  ]);
});

Deno.test("recordRounds answers a failed call with an error result so the round stays paired", async () => {
  const rounds = await recordRounds(streamOf([
    startStep(),
    toolCall("tu_0", "search_products", "sig-0"),
    {
      type: "tool-error",
      toolCallId: "tu_0",
      toolName: "search_products",
      input: { query: "tu_0" },
      error: new Error("connection reset"),
      dynamic: true,
    },
    finishStep("tool-calls"),
  ]));

  assertEquals(rounds[1], {
    role: "user",
    content: [{ type: "tool_result", tool_use_id: "tu_0", content: { error: TOOL_FAILURE_TEXT } }],
  });
});

Deno.test("recordRounds leaves out a step the stream never finished", async () => {
  const rounds = await recordRounds(streamOf([
    startStep(),
    toolCall("tu_0", "search_products", "sig-0"),
    toolResult("tu_0", "search_products"),
    finishStep("tool-calls"),
    startStep(),
    toolCall("tu_1", "search_products", "sig-1"),
    { type: "error", error: new Error("stream dropped") },
  ]));

  assertEquals(rounds.map((m) => m.role), ["assistant", "user"]);
});

Deno.test("recordRounds reports each call and result as it streams", async () => {
  const events: ChatEvent[] = [];
  await recordRounds(
    streamOf([
      startStep(),
      toolCall("tu_0", "search_products", "sig-0"),
      toolResult("tu_0", "search_products"),
      finishStep("tool-calls"),
    ]),
    (ev) => events.push(ev),
  );

  assertEquals(events, [
    { type: "tool_use", id: "tu_0", name: "search_products", input: { query: "tu_0" } },
    { type: "tool_result", tool_use_id: "tu_0", content: { items: [{ id: "tu_0-item" }] } },
  ]);
});
