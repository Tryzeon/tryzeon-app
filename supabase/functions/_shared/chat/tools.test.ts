import { assert, assertEquals, assertStringIncludes } from "@std/assert";
import { z } from "zod";
import { asSchema, type JSONSchema7, zodSchema } from "ai";
import {
  answerSchema,
  buildTools,
  runSearchProducts,
  runSearchWardrobe,
} from "./tools.ts";
import type { DbClient } from "../supabase.ts";

const CATEGORIES = new Map([["pants", "cat-pants"]]);

function schemaObject(
  definition: JSONSchema7["items"],
  label: string,
): JSONSchema7 {
  assert(
    typeof definition === "object" && !Array.isArray(definition),
    `${label} must be a single schema object`,
  );
  return definition;
}

const rpcMustNotRun = {
  rpc: () => {
    throw new Error("rpc must not be called");
  },
} as unknown as DbClient;

/** Records every filter the wardrobe search applied to the query builder. */
function fakeWardrobeClient(rows: Record<string, unknown>[] = []) {
  const eqCalls: Array<[string, string]> = [];
  const containsCalls: Array<[string, string[]]> = [];
  const chain = {
    eq(column: string, value: string) {
      eqCalls.push([column, value]);
      return chain;
    },
    order: () => chain,
    limit: () => chain,
    contains(column: string, value: string[]) {
      containsCalls.push([column, value]);
      return chain;
    },
    then(resolve: (r: { data: unknown; error: null }) => unknown) {
      return Promise.resolve({ data: rows, error: null }).then(resolve);
    },
  };
  const client = {
    from: () => ({ select: () => chain }),
  } as unknown as DbClient;
  return { client, eqCalls, containsCalls };
}

Deno.test("runSearchProducts rejects an unknown category_code without reaching the RPC", async () => {
  const result = await runSearchProducts(
    rpcMustNotRun,
    { category_code: "長褲" },
    CATEGORIES,
  );
  assertEquals(result.items, []);
  assertStringIncludes(result.error ?? "", "長褲");
});

Deno.test("runSearchProducts resolves a known category_code into the RPC's id filter", async () => {
  const seen: Record<string, unknown>[] = [];
  const client = {
    rpc: (_name: string, params: Record<string, unknown>) => {
      seen.push(params);
      return Promise.resolve({ data: [{ id: "p1", name: "褲" }], error: null });
    },
  } as unknown as DbClient;

  const result = await runSearchProducts(
    client,
    { category_code: "pants" },
    CATEGORIES,
  );

  assertEquals(seen.length, 1);
  assertEquals(seen[0].p_category_ids, ["cat-pants"]);
  assertEquals(result.error, undefined);
  assertEquals(result.items.map((i) => i.id), ["p1"]);
});

Deno.test("runSearchWardrobe filters on garment_type", async () => {
  const { client, eqCalls } = fakeWardrobeClient([{ id: "w1" }]);
  const result = await runSearchWardrobe(client, "u1", {
    garment_type: "pants",
  });

  assertEquals(eqCalls, [["user_id", "u1"], ["garment_type", "pants"]]);
  assertEquals(result, { items: [{ id: "w1" }] });
});

Deno.test("runSearchWardrobe applies no garment_type filter when none is given", async () => {
  const { client, eqCalls, containsCalls } = fakeWardrobeClient();
  await runSearchWardrobe(client, "u1", { tags: ["寬鬆"] });

  assertEquals(eqCalls, [["user_id", "u1"]]);
  assertEquals(containsCalls, [["tags", ["寬鬆"]]]);
});

Deno.test("answerSchema emits its block union as anyOf, which Vertex constrains, never oneOf", () => {
  const json = JSON.stringify(z.toJSONSchema(answerSchema));
  assertStringIncludes(json, '"anyOf"');
  assert(!json.includes('"oneOf"'));
});

Deno.test("answerSchema rejects a block missing the field its type requires", () => {
  for (
    const block of [{ type: "text" }, { type: "picks" }, { type: "outfits" }]
  ) {
    assertEquals(
      answerSchema.safeParse({ blocks: [block] }).success,
      false,
      block.type,
    );
  }
});

Deno.test("answerSchema requires color on every item ref", () => {
  const json = z.toJSONSchema(answerSchema, { io: "input" });
  const text = JSON.stringify(json);
  const refs = [...text.matchAll(/"required":\[([^\]]*)\]/g)]
    .map((m) => m[1])
    .filter((required) =>
      required.includes('"type"') && required.includes('"id"')
    );
  assert(refs.length > 0);
  for (const required of refs) assertStringIncludes(required, '"color"');
});

Deno.test("answerSchema accepts each block type with its field", () => {
  const parsed = answerSchema.safeParse({
    blocks: [
      { type: "text", text: "hi" },
      {
        type: "picks",
        picks: [{ type: "product", id: "p1", color: "", highlight: "麻料" }],
      },
      {
        type: "outfits",
        outfits: [{
          title: "週末",
          pieces: [{ type: "product", id: "p1", color: "" }, {
            type: "wardrobe",
            id: "w1",
            color: "",
          }],
        }],
      },
    ],
  });
  assertEquals(parsed.success, true);
});

Deno.test("answerSchema asks Vertex for suggestions as a required string array", async () => {
  const json = await zodSchema(answerSchema).jsonSchema;
  assert(
    json.required?.includes("suggestions"),
    "suggestions must be required",
  );
  const suggestions = schemaObject(json.properties?.suggestions, "suggestions");
  assertEquals(suggestions.type, "array");
  const items = schemaObject(suggestions.items, "suggestions.items");
  assertEquals(items.type, "string");
});

Deno.test("answerSchema never rejects an answer over its suggestions", () => {
  const blocks = [{ type: "text", text: "嗨" }];
  assertEquals(answerSchema.safeParse({ blocks }).success, true);
  assertEquals(
    answerSchema.safeParse({ blocks, suggestions: [1] }).success,
    true,
  );
  assertEquals(
    answerSchema.safeParse({ blocks, suggestions: "單品" }).success,
    true,
  );
});

Deno.test("search_products explains each style value with its Chinese name", async () => {
  const tools = buildTools({
    client: rpcMustNotRun,
    userId: "u1",
    categoryIdByCode: CATEGORIES,
  });
  const json = await asSchema(tools.search_products.inputSchema).jsonSchema;
  const { description } = schemaObject(json.properties?.styles, "styles");
  assert(description, "styles must carry a description");
  assertStringIncludes(description, "basic（簡約基本）");
  assertStringIncludes(description, "homewear（居家舒適）");
});
