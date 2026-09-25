import { describe, expect, it } from "vitest";
import { dehydrateBlock, parseChatLine, userText } from "./chat-wire";

describe("parseChatLine", () => {
  it("turns a tool_use event into a transcript block", () => {
    expect(parseChatLine('{"type":"tool_use","id":"t1","name":"search_products","input":{"query":"襯衫"}}'))
      .toEqual({
        type: "tool_use",
        block: { type: "tool_use", id: "t1", name: "search_products", input: { query: "襯衫" } },
      });
  });

  it("turns a tool_result event into a transcript block", () => {
    expect(parseChatLine('{"type":"tool_result","tool_use_id":"t1","content":{"items":[]}}'))
      .toEqual({
        type: "tool_result",
        block: { type: "tool_result", tool_use_id: "t1", content: { items: [] } },
      });
  });

  it("takes the answer blocks off done", () => {
    const line = JSON.stringify({
      type: "done",
      message: { role: "assistant", content: [{ type: "text", text: "好" }] },
      usage: null,
    });
    expect(parseChatLine(line)).toEqual({ type: "done", blocks: [{ type: "text", text: "好" }] });
  });

  it("keeps the error code", () => {
    expect(parseChatLine('{"type":"error","code":"RATE_LIMIT_EXCEEDED"}'))
      .toEqual({ type: "error", code: "RATE_LIMIT_EXCEEDED" });
  });

  it("ignores blank, malformed and unknown lines", () => {
    expect(parseChatLine("")).toBeNull();
    expect(parseChatLine("{nope")).toBeNull();
    expect(parseChatLine('{"type":"ping"}')).toBeNull();
  });
});

describe("dehydrateBlock", () => {
  it("sends a recommended product back by id only", () => {
    expect(dehydrateBlock({ type: "product", item: { id: "p1", name: "襯衫" } }))
      .toEqual({ type: "product", id: "p1" });
  });

  it("drops a product with no id and passes text through", () => {
    expect(dehydrateBlock({ type: "product", item: {} })).toBeNull();
    expect(dehydrateBlock({ type: "text", text: "嗨" })).toEqual({ type: "text", text: "嗨" });
  });
});

describe("userText", () => {
  it("is a user message with one text block", () => {
    expect(userText("嗨")).toEqual({ role: "user", content: [{ type: "text", text: "嗨" }] });
  });
});
