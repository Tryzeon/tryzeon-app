import { assertEquals, assertStringIncludes } from "@std/assert";
import { buildChatContext } from "./context.ts";
import { STYLING_GUIDE } from "./styling-guide.ts";
import type { DbClient } from "../supabase.ts";

const client = {
  from: (table: string) =>
    table === "product_categories"
      ? {
        select: () =>
          Promise.resolve({
            data: [{ id: "cat-1", code: "tops", name: "上衣" }],
            error: null,
          }),
      }
      : {
        select: () => ({
          eq: () => ({
            maybeSingle: () => Promise.resolve({ data: null, error: null }),
          }),
        }),
      },
} as unknown as DbClient;

Deno.test("buildChatContext grounds the system instruction in the styling guide", async () => {
  const { systemInstruction } = await buildChatContext(client, "u1");
  assertStringIncludes(systemInstruction, STYLING_GUIDE);
});

Deno.test("buildChatContext asks for rows of recommendations, not part labels", async () => {
  const { systemInstruction } = await buildChatContext(client, "u1");
  assertStringIncludes(systemInstruction, "每個 block 的 type 只能是 text 或 recommendation");
  assertEquals(systemInstruction.includes("部位短標"), false);
});
