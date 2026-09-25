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

describe("chat reducer", () => {
  it("opens a turn with the user's message", () => {
    const s = sent();
    expect(s.turn).toEqual([{ role: "user", content: [{ type: "text", text: "找襯衫" }] }]);
    expect(s.history).toEqual([]);
    expect(s.entries).toEqual([{ kind: "user", text: "找襯衫" }]);
  });

  it("ignores a send while a turn is running", () => {
    const s = sent();
    expect(reduce(s, { type: "send", text: "再一次" })).toBe(s);
  });

  it("keeps tool rounds in the turn, out of the committed history", () => {
    let s = sent();
    s = reduce(s, {
      type: "event",
      event: {
        type: "tool_use",
        block: { type: "tool_use", id: "t1", name: "search_products", input: {} },
      },
    });
    s = reduce(s, {
      type: "event",
      event: { type: "tool_result", block: { type: "tool_result", tool_use_id: "t1", content: {} } },
    });
    expect(s.turn).toHaveLength(3);
    expect(s.history).toEqual([]);
  });

  it("commits the turn and the dehydrated answer on done", () => {
    let s = sent();
    s = reduce(s, {
      type: "event",
      event: {
        type: "done",
        blocks: [{ type: "text", text: "推薦這件" }, { type: "product", item: PRODUCT }],
      },
    });
    expect(s.turn).toBeNull();
    expect(s.history).toEqual([
      { role: "user", content: [{ type: "text", text: "找襯衫" }] },
      { role: "assistant", content: [{ type: "text", text: "推薦這件" }, { type: "product", id: "p1" }] },
    ]);
    expect(s.entries.slice(1)).toEqual([
      { kind: "text", text: "推薦這件" },
      { kind: "product", item: buildCatalogItem(PRODUCT, "https://img") },
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
    const done = reduce(sent(), { type: "event", event: { type: "done", blocks: [{ type: "text", text: "好" }] } });
    expect(reduce(done, { type: "ended" })).toBe(done);
  });

  it("shows a recommended wardrobe item by its image and sends it back by id", () => {
    const s = reduce(sent(), {
      type: "event",
      event: {
        type: "done",
        blocks: [{ type: "wardrobe", item: { id: "w1", image_path: "u1/w1.jpg" } }],
      },
    });
    expect(lastEntry(s)).toEqual({ kind: "wardrobe", imagePath: "u1/w1.jpg" });
    expect(s.history[s.history.length - 1]).toEqual({
      role: "assistant",
      content: [{ type: "wardrobe", id: "w1" }],
    });
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
        event: {
          type: "tool_use",
          block: { type: "tool_use", id: `t${i}`, name: "search_products", input: {} },
        },
      });
      s = reduce(s, {
        type: "event",
        event: { type: "tool_result", block: { type: "tool_result", tool_use_id: `t${i}`, content: {} } },
      });
      s = reduce(s, { type: "event", event: { type: "done", blocks: [{ type: "text", text: `a${i}` }] } });
    }
    expect(s.history.length).toBeLessThanOrEqual(HISTORY_LIMIT);
    expect(s.history[0]).toEqual({ role: "user", content: [{ type: "text", text: expect.stringMatching(/^q/) }] });
  });
});
