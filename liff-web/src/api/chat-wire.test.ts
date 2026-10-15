import { describe, expect, it } from "vitest";
import { parseChatLine, userText } from "./chat-wire";

describe("parseChatLine", () => {
  it("takes the turn's messages and the items they name off done", () => {
    const messages = [
      {
        role: "assistant",
        content: [
          { type: "tool_use", id: "t1", name: "search_wardrobe", input: {} },
          { type: "tool_use", id: "t2", name: "search_products", input: { query: "襯衫" } },
        ],
      },
      {
        role: "user",
        content: [
          { type: "tool_result", tool_use_id: "t1", content: { items: [] } },
          { type: "tool_result", tool_use_id: "t2", content: { items: [] } },
        ],
      },
      { role: "assistant", content: [{ type: "text", text: "好" }, { type: "recommendation", items: [{ type: "product", id: "p1" }] }] },
    ];
    const items = { products: { p1: { id: "p1", name: "襯衫" } }, wardrobe: {} };
    const line = JSON.stringify({ type: "done", messages, items, usage: null });
    expect(parseChatLine(line)).toEqual({ type: "done", messages, items });
  });

  it("drops a malformed message and a malformed item map", () => {
    const line = JSON.stringify({
      type: "done",
      messages: [
        { role: "system", content: [] },
        { role: "assistant" },
        { role: "assistant", content: [{ type: "text", text: "好" }] },
      ],
      items: { products: [], wardrobe: { w1: { id: "w1" } } },
    });
    expect(parseChatLine(line)).toEqual({
      type: "done",
      messages: [{ role: "assistant", content: [{ type: "text", text: "好" }] }],
      items: { products: {}, wardrobe: { w1: { id: "w1" } } },
    });
  });

  it("keeps the error code", () => {
    expect(parseChatLine('{"type":"error","code":"RATE_LIMIT_EXCEEDED"}'))
      .toEqual({ type: "error", code: "RATE_LIMIT_EXCEEDED" });
  });

  it("ignores blank, malformed, unknown and progress-only lines", () => {
    expect(parseChatLine("")).toBeNull();
    expect(parseChatLine("{nope")).toBeNull();
    expect(parseChatLine('{"type":"ping"}')).toBeNull();
    expect(parseChatLine('{"type":"tool_use","id":"t1","name":"search_products","input":{}}')).toBeNull();
  });
});

describe("userText", () => {
  it("is a user message with one text block", () => {
    expect(userText("嗨")).toEqual({ role: "user", content: [{ type: "text", text: "嗨" }] });
  });
});
