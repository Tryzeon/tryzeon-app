import { assertEquals, assertStringIncludes } from "@std/assert";
import { type ChatHandlerDeps, handleTextMessage } from "./chat-handler.ts";
import {
  type AnswerItems,
  type ChatParams,
  type AnswerBlock,
  LIMITS,
  type RunChatAgentDeps,
  runChatAgent,
} from "../_shared/chat/index.ts";
import { RateLimitedError } from "../_shared/errors.ts";
import { ValidationError } from "../_shared/validation.ts";
import type { LineApi } from "./line-api.ts";
import type { ChatMessage } from "../_shared/chat/index.ts";
import { fakeConversations } from "./conversation.testing.ts";

const USER = "Uline123";
const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

function fakeLine(opts: { loadingFails?: boolean; replyFails?: boolean } = {}) {
  const replied: object[][] = [];
  const pushed: object[][] = [];
  const loading: string[] = [];
  const line: LineApi = {
    reply: (_token, messages) => {
      if (opts.replyFails) return Promise.reject(new Error("Invalid reply token"));
      replied.push(messages);
      return Promise.resolve();
    },
    push: (_to, messages) => {
      pushed.push(messages);
      return Promise.resolve();
    },
    getContent: () => Promise.resolve(new Uint8Array()),
    showLoading: (to) => {
      loading.push(to);
      return opts.loadingFails
        ? Promise.reject(new Error("loading down"))
        : Promise.resolve();
    },
    getDisplayName: () => Promise.resolve(undefined),
  };
  return { line, replied, pushed, loading };
}

/**
 * Typed as `runChatAgent` itself, so a rename in `ChatParams` fails the build
 * here rather than leaving the assertions below silently reading `undefined`.
 */
function fakeChat(
  outcome:
    | { blocks: AnswerBlock[]; rounds?: ChatMessage[]; items?: AnswerItems }
    | { throws: unknown },
) {
  const seen: { params: ChatParams; deps: RunChatAgentDeps }[] = [];
  const runChat: typeof runChatAgent = (_client, params, deps) => {
    seen.push({ params, deps: deps ?? {} });
    if ("throws" in outcome) return Promise.reject(outcome.throws);
    return Promise.resolve({
      messages: [...outcome.rounds ?? [], { role: "assistant", content: outcome.blocks }],
      answer: outcome.blocks,
      items: outcome.items ?? { products: {}, wardrobe: {} },
    });
  };
  return { runChat, seen };
}

function deps(over: Partial<ChatHandlerDeps> = {}): ChatHandlerDeps {
  return {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line: fakeLine().line,
    imagesBaseUrl: "https://img.example",
    liffUrl: "https://liff.example",
    conversations: fakeConversations().store,
    getOrCreateUserId: () => Promise.resolve("user-uuid"),
    ...over,
  };
}

const textOf = (message: object) => (message as { text: string }).text;

async function captureConsole(
  method: "error" | "warn",
  fn: () => Promise<void>,
): Promise<unknown[][]> {
  const real = console[method];
  const calls: unknown[][] = [];
  console[method] = (...args: unknown[]) => {
    calls.push(args);
  };
  try {
    await fn();
  } finally {
    console[method] = real;
  }
  return calls;
}

Deno.test("runs one turn for the incoming message and replies with the answer", async () => {
  const { line, replied, loading } = fakeLine();
  const chat = fakeChat({ blocks: [{ type: "text", text: "為你找到" }] });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    replyToken: "rt",
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertEquals(loading, [USER]);
  assertEquals(chat.seen[0].params.userId, "user-uuid");
  assertEquals(chat.seen[0].params.messages, [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ]);
  assertEquals(replied, [[{ type: "text", text: "為你找到" }]]);
});

Deno.test("substitutes this channel's hydrator, and nothing else", async () => {
  const chat = fakeChat({ blocks: [{ type: "text", text: "好" }] });

  await handleTextMessage(deps({ runChat: chat.runChat }), {
    replyToken: "rt",
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertEquals(Object.keys(chat.seen[0].deps), ["hydrate"]);
});

Deno.test("rejects an over-long message before charging anything", async () => {
  const { line, replied } = fakeLine();
  const chat = fakeChat({ blocks: [] });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    replyToken: "rt",
    sourceUserId: USER,
    text: "x".repeat(LIMITS.MAX_TEXT_LENGTH + 1),
  });

  assertEquals(chat.seen.length, 0);
  assertStringIncludes(textOf(replied[0][0]), "太長");
});

Deno.test("reports a rate limit in this channel's words", async () => {
  const { line, replied } = fakeLine();
  const chat = fakeChat({ throws: new RateLimitedError() });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    replyToken: "rt",
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertEquals(textOf(replied[0][0]), "今天聊得比較多了，休息一下再來找我。");
});

Deno.test("reports an unexpected failure as a generic apology", async () => {
  const { line, replied } = fakeLine();
  const chat = fakeChat({ throws: new Error("vertex exploded") });

  const errors = await captureConsole("error", () =>
    handleTextMessage(deps({ line, runChat: chat.runChat }), {
      replyToken: "rt",
      sourceUserId: USER,
      text: "找白襯衫",
    }));

  assertStringIncludes(textOf(replied[0][0]), "稍後再試");
  assertEquals(errors.length, 1);
});

Deno.test("a failed typing indicator does not cost the caller their answer", async () => {
  const { line, replied } = fakeLine({ loadingFails: true });
  const chat = fakeChat({ blocks: [{ type: "text", text: "為你找到" }] });

  await captureConsole("warn", () =>
    handleTextMessage(deps({ line, runChat: chat.runChat }), {
      replyToken: "rt",
      sourceUserId: USER,
      text: "找白襯衫",
    }));

  assertEquals(replied, [[{ type: "text", text: "為你找到" }]]);
});

Deno.test("the turn runs on the stored conversation plus this message", async () => {
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
    {
      role: "assistant",
      content: [
        { type: "text", text: "為你找到" },
        { type: "picks", picks: [{ type: "product", id: PID }] },
      ],
    },
  ];
  const conversations = fakeConversations({ prior });
  const chat = fakeChat({ blocks: [{ type: "text", text: "這件比較便宜" }] });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { replyToken: "rt", sourceUserId: USER, text: "有便宜一點的嗎" },
  );

  assertEquals(chat.seen[0].params.messages, [
    ...prior,
    { role: "user", content: [{ type: "text", text: "有便宜一點的嗎" }] },
  ]);
});

Deno.test("the whole turn is written back as the core recorded it", async () => {
  const conversations = fakeConversations();
  const chat = fakeChat({
    blocks: [
      { type: "text", text: "為你找到" },
      { type: "picks", picks: [{ type: "product", id: PID }] },
    ],
    items: {
      products: {
        [PID]: {
          id: PID,
          name: "短版牛仔外套",
          price: 1280,
          imageUrl: "https://img.example/p.jpg",
          storeName: "某店",
          purchaseUrl: null,
        },
      },
      wardrobe: {},
    },
    rounds: [
      {
        role: "assistant",
        content: [{ type: "tool_use", id: "t1", name: "search_products", input: {} }],
      },
      {
        role: "user",
        content: [{ type: "tool_result", tool_use_id: "t1", content: { items: [] } }],
      },
    ],
  });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { replyToken: "rt", sourceUserId: USER, text: "找外套" },
  );

  assertEquals(conversations.writes.length, 1);
  assertEquals(conversations.writes[0], [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
    {
      role: "assistant",
      content: [{ type: "tool_use", id: "t1", name: "search_products", input: {} }],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "t1", content: { items: [] } }],
    },
    {
      role: "assistant",
      content: [
        { type: "text", text: "為你找到" },
        { type: "picks", picks: [{ type: "product", id: PID }] },
      ],
    },
  ]);
});

Deno.test("a failed turn leaves the conversation untouched", async () => {
  const conversations = fakeConversations();
  const chat = fakeChat({ throws: new RateLimitedError() });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { replyToken: "rt", sourceUserId: USER, text: "找外套" },
  );

  assertEquals(conversations.writes, []);
});

Deno.test("a validation failure writes nothing either, stored transcript or not", async () => {
  // No failure kind is special-cased: every one of them leaves the store as it
  // was, including a validation error that blames the replayed history.
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
  ];
  const conversations = fakeConversations({ prior });
  const chat = fakeChat({ throws: new ValidationError("messages too long") });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { replyToken: "rt", sourceUserId: USER, text: "有便宜一點的嗎" },
  );

  assertEquals(conversations.writes, []);
});

Deno.test("the answer is replied before the conversation is written", async () => {
  const trace: string[] = [];
  const { line } = fakeLine();
  const tracingLine: LineApi = {
    ...line,
    reply: () => {
      trace.push("reply");
      return Promise.resolve();
    },
  };
  const conversations = fakeConversations({ onSave: () => trace.push("save") });
  const chat = fakeChat({ blocks: [{ type: "text", text: "好" }] });

  await handleTextMessage(
    deps({
      line: tracingLine,
      runChat: chat.runChat,
      conversations: conversations.store,
    }),
    { replyToken: "rt", sourceUserId: USER, text: "找外套" },
  );

  assertEquals(trace, ["reply", "save"]);
});

Deno.test("an expired reply token costs a push, not the answer", async () => {
  const { line, replied, pushed } = fakeLine({ replyFails: true });
  const chat = fakeChat({ blocks: [{ type: "text", text: "為你找到" }] });

  const warnings = await captureConsole("warn", () =>
    handleTextMessage(deps({ line, runChat: chat.runChat }), {
      replyToken: "rt",
      sourceUserId: USER,
      text: "找白襯衫",
    }));

  assertEquals(replied, []);
  assertEquals(pushed, [[{ type: "text", text: "為你找到" }]]);
  assertEquals(warnings.length, 1);
});

Deno.test("a recommended product in the reply opens its LIFF product page", async () => {
  const { line, replied } = fakeLine();
  const chat = fakeChat({
    blocks: [{ type: "picks", picks: [{ type: "product", id: PID }] }],
    items: {
      products: {
        [PID]: {
          id: PID,
          name: "短版牛仔外套",
          price: 1280,
          imageUrl: "https://img.example/p.jpg",
          storeName: "某店",
          purchaseUrl: null,
        },
      },
      wardrobe: {},
    },
  });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    replyToken: "rt",
    sourceUserId: USER,
    text: "找外套",
  });

  // deno-lint-ignore no-explicit-any
  const [bubble] = (replied[0][0] as any).contents.contents;
  assertEquals(bubble.hero.action.uri, `https://liff.example/product/${PID}`);
});
