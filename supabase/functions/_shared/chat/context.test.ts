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

Deno.test("buildChatContext asks for rows of picks or of whole outfits, never part rows", async () => {
  const { systemInstruction } = await buildChatContext(client, "u1");
  assertStringIncludes(
    systemInstruction,
    "每個 block 的 type 只能是 text、picks 或 outfits",
  );
  assertStringIncludes(systemInstruction, "每套 2–3 件");
  assertStringIncludes(systemInstruction, "highlight");
  assertEquals(systemInstruction.includes("recommendation"), false);
  assertEquals(systemInstruction.includes("每個部位一個"), false);
  assertEquals(systemInstruction.includes("部位短標"), false);
});

Deno.test("buildChatContext points the styling rationale at an outfit's reason", async () => {
  const { systemInstruction } = await buildChatContext(client, "u1");
  assertStringIncludes(STYLING_GUIDE, "寫進該套的 reason");
  assertStringIncludes(systemInstruction, "reason");
});

Deno.test("buildChatContext asks for suggestions in the user's voice, only for what chat can do", async () => {
  const { systemInstruction } = await buildChatContext(client, "u1");
  assertStringIncludes(systemInstruction, "suggestions");
  assertStringIncludes(systemInstruction, "使用者的口吻");
  assertStringIncludes(systemInstruction, "≤ 20 字");
  assertStringIncludes(systemInstruction, "不可建議試穿");
});
