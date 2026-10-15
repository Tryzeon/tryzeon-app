import { assertEquals } from "@std/assert";
import { LIMITS } from "../_shared/chat/index.ts";
import {
  photoNote,
  redisConversations,
  type RedisLike,
  tryonNote,
  wardrobeTryonNote,
} from "./conversation.ts";
import type { ChatMessage } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

const someProduct = (over: Partial<LineProduct> = {}): LineProduct => ({
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

Deno.test("a try-on is recorded as a user turn naming the product", () => {
  const note = tryonNote(someProduct());

  assertEquals(note.role, "user");
  assertEquals(note.content, [{
    type: "text",
    text: `（使用者剛試穿了商品 id:${PID}「短版牛仔外套」）`,
  }]);
});

Deno.test("an absurd product name cannot dominate the transcript", () => {
  const note = tryonNote(someProduct({ name: "衣".repeat(60) }));

  assertEquals(
    (note.content[0] as { text: string }).text,
    `（使用者剛試穿了商品 id:${PID}「${"衣".repeat(40)}…」）`,
  );
});

Deno.test("a forwarded photo is recorded as a user turn describing what was sent", () => {
  const note = photoNote("淺藍色寬鬆棉質抽繩長褲");

  assertEquals(note.role, "user");
  assertEquals(note.content, [{
    type: "text",
    text: "（使用者傳了一張衣物照片：淺藍色寬鬆棉質抽繩長褲）",
  }]);
});

interface SetCall {
  key: string;
  value: unknown;
  opts: { ex: number };
}

function fakeRedis(opts: { stored?: unknown; fails?: boolean } = {}) {
  const gets: string[] = [];
  const sets: SetCall[] = [];
  const down = () => Promise.reject(new Error("upstash down"));
  const client: RedisLike = {
    get: (key) => {
      gets.push(key);
      return opts.fails ? down() : Promise.resolve(opts.stored ?? null);
    },
    set: (key, value, o) => {
      sets.push({ key, value, opts: o });
      return opts.fails ? down() : Promise.resolve("OK");
    },
  };
  return { client, gets, sets };
}

async function captureWarnings(fn: () => Promise<void>): Promise<unknown[][]> {
  const real = console.warn;
  const calls: unknown[][] = [];
  console.warn = (...args: unknown[]) => {
    calls.push(args);
  };
  try {
    await fn();
  } finally {
    console.warn = real;
  }
  return calls;
}

Deno.test("a conversation is read back under this channel's key", async () => {
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ];
  const { client, gets } = fakeRedis({ stored: prior });

  assertEquals(await redisConversations(client).load("Uline123"), prior);
  assertEquals(gets, ["line:conv:Uline123"]);
});

Deno.test("no stored conversation is an empty one, not a failure", async () => {
  const { client } = fakeRedis({ stored: null });

  assertEquals(await redisConversations(client).load("Uline123"), []);
});

Deno.test("a stored value of the wrong shape is discarded", async () => {
  const { client } = fakeRedis({ stored: { messages: [] } });

  assertEquals(await redisConversations(client).load("Uline123"), []);
});

Deno.test("a write carries the idle window as the key's TTL", async () => {
  const { client, sets } = fakeRedis();
  const messages: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ];

  await redisConversations(client).save("Uline123", messages);

  assertEquals(sets, [{
    key: "line:conv:Uline123",
    value: messages,
    opts: { ex: 1800 },
  }]);
});

Deno.test("a write keeps only the latest window of the conversation", async () => {
  const { client, sets } = fakeRedis();
  const messages: ChatMessage[] = Array.from(
    { length: LIMITS.MAX_MESSAGES + 3 },
    (_, i) => ({ role: "user", content: [{ type: "text", text: `m${i}` }] }),
  );

  await redisConversations(client).save("Uline123", messages);

  assertEquals(sets[0].value, messages.slice(3));
});

Deno.test("a store that is down costs continuity, not the turn", async () => {
  const store = redisConversations(fakeRedis({ fails: true }).client);

  const warnings = await captureWarnings(async () => {
    assertEquals(await store.load("Uline123"), []);
    await store.save("Uline123", []);
  });

  assertEquals(warnings.length, 2);
});

Deno.test("a finished wardrobe try-on is written back with what it was", () => {
  const note = wardrobeTryonNote({
    id: "44444444-4444-4444-4444-444444444444",
    garmentTypeLabel: "上衣",
    tags: ["寬鬆", "米色"],
  });

  assertEquals(note.role, "user");
  assertEquals(
    note.content[0].text,
    "（使用者剛試穿了自己衣櫃裡的單品 id:44444444-4444-4444-4444-444444444444「上衣 #寬鬆 #米色」）",
  );
});

Deno.test("a tag-less wardrobe note still reads as a sentence", () => {
  const note = wardrobeTryonNote({ id: "w1", garmentTypeLabel: "外套", tags: [] });
  assertEquals(note.content[0].text, "（使用者剛試穿了自己衣櫃裡的單品 id:w1「外套」）");
});

Deno.test("a pathologically long tag cannot blow up the transcript note", () => {
  // Tags are free text with no constraint, so one absurd tag could exceed
  // LIMITS.MAX_TEXT_LENGTH and break the sender's next chat turn.
  const longTag = "x".repeat(500);
  const note = wardrobeTryonNote({
    id: "w1",
    garmentTypeLabel: "外套",
    tags: [longTag],
  });

  const text = note.content[0].text as string;
  assertEquals(text.length < LIMITS.MAX_TEXT_LENGTH, true);
  assertEquals(text.includes("…"), true);
});
