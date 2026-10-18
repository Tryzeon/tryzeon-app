import { assertEquals, assertRejects } from "@std/assert";
import { runChatAgent } from "./run.ts";
import { ValidationError } from "../validation.ts";
import { type DailyUsage, QuotaExceededError } from "../quota.ts";
import type {
  AgentRequest,
  AgentRunner,
  AnswerBlock,
  AnswerHydrator,
  ChatEvent,
  ChatMessage,
  ChatParams,
  ChatQuotaFactory,
  ContentBlock,
  ContextLoader,
} from "./types.ts";
import type { DbClient } from "../supabase.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 0,
  chat_count: 1,
  video_count: 0,
};

const client = {} as unknown as DbClient;

const PRODUCT_ID = "f8f49d33-e34a-4121-a6b9-f654e0614971";
const WARDROBE_ID = "0b2c3d4e-5f60-4718-8293-a4b5c6d7e8f9";

const params: ChatParams = {
  userId: "u1",
  messages: [{ role: "user", content: [{ type: "text", text: "找白襯衫" }] }],
};

function fakeQuota(allowed = true) {
  const calls: string[] = [];
  const factory: ChatQuotaFactory = () => ({
    charge() {
      calls.push("charge");
      return Promise.resolve({ allowed, usage: USAGE });
    },
    refund() {
      calls.push("refund");
      return Promise.resolve();
    },
  });
  return { factory, calls };
}

const context: ContextLoader = () =>
  Promise.resolve({
    systemInstruction: "SYSTEM",
    categoryIdByCode: new Map([["tops", "cat-1"]]),
  });

function fakeAgent(
  answer: { output: Record<string, unknown> | null; rounds?: ChatMessage[] },
): { runner: AgentRunner; seen: AgentRequest[] } {
  const seen: AgentRequest[] = [];
  return {
    seen,
    runner: (req) => {
      seen.push(req);
      return Promise.resolve({ output: answer.output, rounds: answer.rounds ?? [] });
    },
  };
}

const hydrator = (
  products: Record<string, ContentBlock>,
  wardrobe: Record<string, ContentBlock> = {},
): AnswerHydrator =>
() =>
  Promise.resolve({
    products: new Map(Object.entries(products)),
    wardrobe: new Map(Object.entries(wardrobe)),
  });

Deno.test("answers with item refs in the model's order and their rows alongside", async () => {
  const quota = fakeQuota();
  const result = await runChatAgent(client, params, {
    quota: quota.factory,
    loadContext: context,
    runAgent: fakeAgent({
      output: {
        blocks: [
          { type: "text", text: "上身" },
          {
            type: "picks",
            picks: [{ type: "product", id: PRODUCT_ID }, { type: "wardrobe", id: WARDROBE_ID }],
          },
        ],
      },
    }).runner,
    hydrate: hydrator(
      { [PRODUCT_ID]: { id: PRODUCT_ID, name: "襯衫" } },
      { [WARDROBE_ID]: { id: WARDROBE_ID } },
    ),
  });

  assertEquals(result.messages, [{
    role: "assistant",
    content: [
      { type: "text", text: "上身" },
      {
        type: "picks",
        picks: [{ type: "product", id: PRODUCT_ID }, { type: "wardrobe", id: WARDROBE_ID }],
      },
    ],
  }]);
  assertEquals(result.items, {
    products: { [PRODUCT_ID]: { id: PRODUCT_ID, name: "襯衫" } },
    wardrobe: { [WARDROBE_ID]: { id: WARDROBE_ID } },
  });
  assertEquals(result.answer, result.messages.at(-1)!.content);
  assertEquals(result.usage, USAGE);
  assertEquals(quota.calls, ["charge"]);
});

Deno.test("returns the tool rounds followed by the answer, ready to append", async () => {
  const rounds: ChatMessage[] = [
    {
      role: "assistant",
      content: [{ type: "tool_use", id: "t0", name: "search_products", input: {} }],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "t0", content: { items: [] } }],
    },
  ];
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks: [{ type: "text", text: "好" }] }, rounds })
      .runner,
    hydrate: hydrator({}),
  });

  assertEquals(result.messages, [
    ...rounds,
    { role: "assistant", content: [{ type: "text", text: "好" }] },
  ]);
});

Deno.test("an unusable model output falls back to text and keeps quota spent", async () => {
  const quota = fakeQuota();
  const result = await runChatAgent(client, params, {
    quota: quota.factory,
    loadContext: context,
    runAgent: fakeAgent({ output: null }).runner,
    hydrate: hydrator({}),
  });

  assertEquals(result.messages.length, 1);
  assertEquals(result.messages[0].content.map((b) => b.type), ["text"]);
  assertEquals(quota.calls, ["charge"]);
});

Deno.test("stores the answer as answerBlocksOf reads it, keeping ids with no row or no uuid", async () => {
  const blocks = [
    { type: "text", text: "  " },
    {
      type: "picks",
      picks: [
        { type: "product", id: PRODUCT_ID, highlight: "超過八個字的亮點說明文字" },
        { type: "product", id: PRODUCT_ID },
        { type: "wardrobe", id: "not-a-uuid" },
      ],
    },
  ];
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks } }).runner,
    hydrate: hydrator({}),
  });

  const answer: AnswerBlock[] = [{
    type: "picks",
    picks: [
      { type: "product", id: PRODUCT_ID, highlight: "超過八個字的亮點說明文字" },
      { type: "wardrobe", id: "not-a-uuid" },
    ],
  }];
  assertEquals(result.messages, [{ role: "assistant", content: answer }]);
  assertEquals(result.answer, answer);
  assertEquals(result.items, { products: {}, wardrobe: {} });
});

Deno.test("an answer whose every row reads as nothing falls back to text without hydrating", async () => {
  let hydrated = false;
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({
      output: {
        blocks: [
          { type: "text", text: "  " },
          { type: "outfits", outfits: [{ title: "單件", pieces: [{ type: "product", id: PRODUCT_ID }] }] },
        ],
      },
    }).runner,
    hydrate: () => {
      hydrated = true;
      return Promise.resolve({ products: new Map(), wardrobe: new Map() });
    },
  });

  assertEquals(result.messages[0].content.map((b) => b.type), ["text"]);
  assertEquals(hydrated, false);
});

Deno.test("items holds every hydrated row", async () => {
  const other = "a1b2c3d4-e5f6-4789-8abc-def012345678";
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({
      output: { blocks: [{ type: "picks", picks: [{ type: "product", id: PRODUCT_ID }] }] },
    }).runner,
    hydrate: hydrator({ [PRODUCT_ID]: { id: PRODUCT_ID }, [other]: { id: other } }),
  });

  assertEquals(Object.keys(result.items.products).sort(), [PRODUCT_ID, other].sort());
});

Deno.test("empty blocks fall back to text without hydrating", async () => {
  let hydrated = false;
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks: [] } }).runner,
    hydrate: () => {
      hydrated = true;
      return Promise.resolve({ products: new Map(), wardrobe: new Map() });
    },
  });

  assertEquals(result.messages[0].content.map((b) => b.type), ["text"]);
  assertEquals(hydrated, false);
});

Deno.test("a non-object entry in blocks is dropped", async () => {
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({
      output: { blocks: [null, "x", 3, [1], { type: "text", text: "好" }] },
    }).runner,
    hydrate: hydrator({}),
  });

  assertEquals(result.messages[0].content, [{ type: "text", text: "好" }]);
});

Deno.test("blocks that are all non-objects fall back to text", async () => {
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks: [null, "x"] } }).runner,
    hydrate: hydrator({}),
  });

  assertEquals(result.messages[0].content.map((b) => b.type), ["text"]);
});

const OUTFIT_BLOCK = {
  type: "outfits",
  outfits: [{
    title: "週末休閒",
    reason: "好搭",
    pieces: [{ type: "product", id: PRODUCT_ID }, { type: "wardrobe", id: WARDROBE_ID }],
  }],
};

Deno.test("answers with an outfits block as stored, and every piece's row alongside", async () => {
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks: [OUTFIT_BLOCK] } }).runner,
    hydrate: hydrator(
      { [PRODUCT_ID]: { id: PRODUCT_ID, name: "襯衫" } },
      { [WARDROBE_ID]: { id: WARDROBE_ID } },
    ),
  });

  assertEquals(result.messages, [{ role: "assistant", content: [OUTFIT_BLOCK] }]);
  assertEquals(result.items, {
    products: { [PRODUCT_ID]: { id: PRODUCT_ID, name: "襯衫" } },
    wardrobe: { [WARDROBE_ID]: { id: WARDROBE_ID } },
  });
});

Deno.test("an outfit with a missing row is stored whole", async () => {
  const result = await runChatAgent(client, params, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: fakeAgent({ output: { blocks: [OUTFIT_BLOCK] } }).runner,
    hydrate: hydrator({ [PRODUCT_ID]: { id: PRODUCT_ID, name: "襯衫" } }),
  });

  assertEquals(result.messages, [{ role: "assistant", content: [OUTFIT_BLOCK] }]);
});

Deno.test("passes the loaded grounding through to the agent", async () => {
  const agent = fakeAgent({ output: { blocks: [{ type: "text", text: "好" }] } });
  const events: ChatEvent[] = [];
  await runChatAgent(client, { ...params, onEvent: (ev) => events.push(ev) }, {
    quota: fakeQuota().factory,
    loadContext: context,
    runAgent: agent.runner,
    hydrate: hydrator({}),
  });

  assertEquals(agent.seen.length, 1);
  assertEquals(agent.seen[0].context.systemInstruction, "SYSTEM");
  assertEquals(agent.seen[0].userId, "u1");
  assertEquals(agent.seen[0].messages, params.messages);
  assertEquals(agent.seen[0].context.categoryIdByCode.get("tops"), "cat-1");
  assertEquals(typeof agent.seen[0].onEvent, "function");
});

Deno.test("rejects over quota without running the agent", async () => {
  const quota = fakeQuota(false);
  let agentCalled = false;
  await assertRejects(
    () =>
      runChatAgent(client, params, {
        quota: quota.factory,
        loadContext: context,
        runAgent: () => {
          agentCalled = true;
          return Promise.resolve({ output: null, rounds: [] });
        },
        hydrate: hydrator({}),
      }),
    QuotaExceededError,
  );
  assertEquals(agentCalled, false);
  assertEquals(quota.calls, ["charge"]);
});

Deno.test("refunds when the agent loop throws, and rethrows the original error", async () => {
  const quota = fakeQuota();
  const boom = new Error("vertex exploded");
  const err = await assertRejects(() =>
    runChatAgent(client, params, {
      quota: quota.factory,
      loadContext: context,
      runAgent: () => Promise.reject(boom),
      hydrate: hydrator({}),
    })
  );
  assertEquals(err, boom);
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("refunds when hydration fails — a lost row is not a graceful answer", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runChatAgent(client, params, {
        quota: quota.factory,
        loadContext: context,
        runAgent: fakeAgent({
          output: { blocks: [{ type: "picks", picks: [{ type: "product", id: PRODUCT_ID }] }] },
        }).runner,
        hydrate: () => Promise.reject(new Error("db down")),
      }),
    Error,
    "db down",
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("refunds when grounding fails", async () => {
  const quota = fakeQuota();
  await assertRejects(() =>
    runChatAgent(client, params, {
      quota: quota.factory,
      loadContext: () => Promise.reject(new Error("no categories")),
      runAgent: fakeAgent({ output: null }).runner,
      hydrate: hydrator({}),
    })
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a refund that itself fails does not mask the original error", async () => {
  const boom = new Error("vertex exploded");
  const err = await assertRejects(() =>
    runChatAgent(client, params, {
      quota: () => ({
        charge: () => Promise.resolve({ allowed: true, usage: USAGE }),
        refund: () => Promise.reject(new Error("refund exploded")),
      }),
      loadContext: context,
      runAgent: () => Promise.reject(boom),
      hydrate: hydrator({}),
    })
  );
  assertEquals(err, boom);
});

Deno.test("validates before charging anything", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runChatAgent(client, { userId: "u1", messages: [] }, {
        quota: quota.factory,
        loadContext: context,
        runAgent: fakeAgent({ output: null }).runner,
        hydrate: hydrator({}),
      }),
    ValidationError,
  );
  assertEquals(quota.calls, []);
});
