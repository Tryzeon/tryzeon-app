import { describe, expect, it } from "vitest";
import { buildCatalogItem } from "../api/catalog-row";
import type { WireMessage } from "../api/chat-wire";
import { createChatReducer, HISTORY_LIMIT, initialChatState, trimHistory, type ChatState } from "./chat";

const reduce = createChatReducer((row) => buildCatalogItem(row, "https://img"));

const PRODUCT = {
  id: "p1",
  name: "白襯衫",
  price: 1280,
  image_paths: ["s/p1.jpg"],
  store_profiles: { name: "小森選物" },
};

function sent(text = "找襯衫"): ChatState {
  return reduce(initialChatState, { type: "send", text });
}

const lastEntry = (s: ChatState) => s.entries[s.entries.length - 1];

const NO_ITEMS = { products: {}, wardrobe: {} };

const answer = (content: WireMessage["content"]): WireMessage => ({ role: "assistant", content });

describe("chat reducer", () => {
  const WARDROBE_ROW = { id: "w1", image_path: "u1/top/w1.png", garment_type: "top", tags: ["白色", "", 3] };

  function answered(
    content: WireMessage["content"],
    items: { products: Record<string, unknown>; wardrobe: Record<string, unknown> } = { products: { p1: PRODUCT }, wardrobe: { w1: WARDROBE_ROW } },
  ) {
    return reduce(sent(), { type: "event", event: { type: "done", messages: [answer(content)], items } });
  }

  it("opens a turn with the user's message", () => {
    const s = sent();
    expect(s.turn).toEqual({ role: "user", content: [{ type: "text", text: "找襯衫" }] });
    expect(s.history).toEqual([]);
    expect(s.entries).toEqual([{ kind: "user", text: "找襯衫" }]);
  });

  it("ignores a send while a turn is running", () => {
    const s = sent();
    expect(reduce(s, { type: "send", text: "再一次" })).toBe(s);
  });

  it("commits the question and the turn's messages exactly as sent", () => {
    const messages: WireMessage[] = [
      {
        role: "assistant",
        content: [{ type: "tool_use", id: "t1", name: "search_products", input: {} }],
      },
      { role: "user", content: [{ type: "tool_result", tool_use_id: "t1", content: { items: [] } }] },
      {
        role: "assistant",
        content: [{ type: "text", text: "推薦這件" }, { type: "picks", picks: [{ type: "product", id: "p1" }] }],
      },
    ];
    let s = sent();
    s = reduce(s, {
      type: "event",
      event: { type: "done", messages, items: { products: { p1: PRODUCT }, wardrobe: {} } },
    });
    expect(s.turn).toBeNull();
    expect(s.history).toEqual([
      { role: "user", content: [{ type: "text", text: "找襯衫" }] },
      ...messages,
    ]);
    expect(s.entries.slice(1)).toEqual([
      { kind: "text", text: "推薦這件" },
      { kind: "picks", picks: [{ item: { kind: "product", item: buildCatalogItem(PRODUCT, "https://img") } }] },
    ]);
  });

  it("drops the whole turn on a rate-limit error and says so", () => {
    let s = sent();
    s = reduce(s, { type: "event", event: { type: "error", code: "RATE_LIMIT_EXCEEDED" } });
    expect(s.turn).toBeNull();
    expect(s.history).toEqual([]);
    expect(lastEntry(s)).toEqual({ kind: "notice", text: "今天的對話次數已用完，明天再來聊。" });
  });

  it("treats a stream that ends without an answer as a failure", () => {
    const s = reduce(sent(), { type: "ended" });
    expect(s.turn).toBeNull();
    expect(s.history).toEqual([]);
    expect(lastEntry(s)).toEqual({ kind: "notice", text: "出了點狀況，請稍後再試。" });
  });

  it("does nothing on ended once the turn is settled", () => {
    const done = reduce(sent(), {
      type: "event",
      event: { type: "done", messages: [answer([{ type: "text", text: "好" }])], items: NO_ITEMS },
    });
    expect(reduce(done, { type: "ended" })).toBe(done);
  });

  it("shows a recommended wardrobe item by its image and sends the row back by id", () => {
    const row = { type: "picks", picks: [{ type: "wardrobe", id: "w1" }] };
    const s = reduce(sent(), {
      type: "event",
      event: {
        type: "done",
        messages: [answer([row])],
        items: { products: {}, wardrobe: { w1: { id: "w1", image_path: "u1/w1.jpg" } } },
      },
    });
    expect(lastEntry(s)).toEqual({
      kind: "picks",
      picks: [{ item: { kind: "wardrobe", id: "w1", imagePath: "u1/w1.jpg", garmentType: null, tags: [] } }],
    });
    expect(s.history[s.history.length - 1]).toEqual({ role: "assistant", content: [row] });
  });

  it("keeps adjacent recommendations as separate rows", () => {
    const s = reduce(sent(), {
      type: "event",
      event: {
        type: "done",
        messages: [answer([
          { type: "picks", picks: [{ type: "product", id: "p1" }] },
          { type: "picks", picks: [{ type: "product", id: "p2" }] },
        ])],
        items: { products: { p1: PRODUCT, p2: { ...PRODUCT, id: "p2" } }, wardrobe: {} },
      },
    });
    expect(s.entries.slice(1).map((e) => e.kind)).toEqual(["picks", "picks"]);
  });

  it("drops items it has no data for, and draws no row left empty", () => {
    const s = reduce(sent(), {
      type: "event",
      event: {
        type: "done",
        messages: [answer([
          { type: "text", text: "這些" },
          { type: "picks", picks: [{ type: "product", id: "gone" }, { type: "product", id: "p1" }] },
          { type: "picks", picks: [{ type: "wardrobe", id: "w-no-image" }, { type: "hat", id: "h1" }] },
          { type: "picks", picks: "p1" },
        ])],
        items: { products: { p1: PRODUCT }, wardrobe: { "w-no-image": { id: "w-no-image" } } },
      },
    });
    expect(s.entries.slice(1)).toEqual([
      { kind: "text", text: "這些" },
      { kind: "picks", picks: [{ item: { kind: "product", item: buildCatalogItem(PRODUCT, "https://img") } }] },
    ]);
  });

  it("carries a highlight and a wardrobe item's type and tags onto the row's picks", () => {
    const s = answered([
      { type: "picks", picks: [{ type: "product", id: "p1", highlight: " 麻料透氣 " }, { type: "wardrobe", id: "w1" }] },
    ]);
    expect(lastEntry(s)).toEqual({
      kind: "picks",
      picks: [
        { item: { kind: "product", item: buildCatalogItem(PRODUCT, "https://img") }, highlight: "麻料透氣" },
        { item: { kind: "wardrobe", id: "w1", imagePath: "u1/top/w1.png", garmentType: "top", tags: ["白色"] } },
      ],
    });
  });

  it("turns an outfits block into one entry of whole looks", () => {
    const s = answered([
      {
        type: "outfits",
        outfits: [
          { title: "週末休閒", reason: "白襯衫配深藍直筒", pieces: [{ type: "product", id: "p1" }, { type: "wardrobe", id: "w1" }] },
          { title: "缺件", pieces: [{ type: "product", id: "p1" }, { type: "product", id: "gone" }] },
          { title: "  ", pieces: [{ type: "product", id: "p1" }, { type: "wardrobe", id: "w1" }] },
        ],
      },
    ]);
    expect(lastEntry(s)).toEqual({
      kind: "outfits",
      outfits: [{
        title: "週末休閒",
        reason: "白襯衫配深藍直筒",
        pieces: [
          { kind: "product", item: buildCatalogItem(PRODUCT, "https://img") },
          { kind: "wardrobe", id: "w1", imagePath: "u1/top/w1.png", garmentType: "top", tags: ["白色"] },
        ],
      }],
    });
  });

  it("draws no entry for an outfits block whose looks all lost a piece", () => {
    const s = answered([
      { type: "text", text: "這套" },
      { type: "outfits", outfits: [{ title: "缺件", pieces: [{ type: "product", id: "gone" }, { type: "product", id: "p1" }] }] },
    ]);
    expect(s.entries.slice(1)).toEqual([{ kind: "text", text: "這套" }]);
  });
});

const turn = (n: number): WireMessage[] => [
  { role: "user", content: [{ type: "text", text: `q${n}` }] },
  { role: "assistant", content: [{ type: "tool_use", id: `t${n}`, name: "search_products", input: {} }] },
  { role: "user", content: [{ type: "tool_result", tool_use_id: `t${n}`, content: {} }] },
  { role: "assistant", content: [{ type: "text", text: `a${n}` }] },
];

describe("trimHistory", () => {
  it("keeps a history that fits", () => {
    const history = [...turn(1), ...turn(2)];
    expect(trimHistory(history, 8)).toBe(history);
  });

  it("drops whole turns from the front so the rest starts at a user question", () => {
    const history = [...turn(1), ...turn(2), ...turn(3)];
    expect(trimHistory(history, 9)).toEqual([...turn(2), ...turn(3)]);
  });

  it("never starts on a tool_result, which would orphan it from its tool_use", () => {
    const history = [...turn(1), ...turn(2)];
    const trimmed = trimHistory(history, 6);
    expect(trimmed).toEqual(turn(2));
    expect(trimmed[0].content[0].type).toBe("text");
  });
});

describe("chat reducer history cap", () => {
  it("keeps the committed history within the cap however long the chat runs", () => {
    let s = initialChatState;
    for (let i = 0; i < 200; i++) {
      s = reduce(s, { type: "send", text: `q${i}` });
      s = reduce(s, {
        type: "event",
        event: { type: "done", messages: turn(i).slice(1), items: NO_ITEMS },
      });
    }
    expect(s.history.length).toBeLessThanOrEqual(HISTORY_LIMIT);
    expect(s.history[0]).toEqual({ role: "user", content: [{ type: "text", text: expect.stringMatching(/^q/) }] });
  });
});
