import { assertEquals, assertRejects } from "@std/assert";
import { supabaseGenerationLog } from "./generations.ts";
import { ValidationError } from "./errors.ts";
import type { DbClient } from "../supabase.ts";

interface Call {
  table: string;
  op: string;
  payload?: Record<string, unknown>;
  eq?: [string, unknown];
}

function only<T>(items: T[]): T {
  assertEquals(items.length, 1);
  return items[0];
}

function fakeAdmin(error: { message: string; code?: string } | null = null) {
  const calls: Call[] = [];
  const client = {
    from(table: string) {
      return {
        insert(payload: Record<string, unknown>) {
          const call: Call = { table, op: "insert", payload };
          calls.push(call);
          return {
            select: () => ({
              single: () =>
                Promise.resolve(
                  error
                    ? { data: null, error }
                    : { data: { id: "g1" }, error: null },
                ),
            }),
          };
        },
        update(payload: Record<string, unknown>) {
          return {
            eq(column: string, value: unknown) {
              calls.push({ table, op: "update", payload, eq: [column, value] });
              return Promise.resolve({ error });
            },
          };
        },
      };
    },
  } as unknown as DbClient;
  return { client, calls };
}

Deno.test("start inserts a pending row and returns its id", async () => {
  const admin = fakeAdmin();
  const id = await supabaseGenerationLog(admin.client).start({
    userId: "u1",
    mode: "video",
  });
  assertEquals(id, "g1");
  assertEquals(admin.calls, [{
    table: "tryon_generations",
    op: "insert",
    payload: { user_id: "u1", mode: "video" },
  }]);
});

Deno.test("start inserts the caller's generation id when it has one", async () => {
  const admin = fakeAdmin();
  await supabaseGenerationLog(admin.client).start({
    id: "6f1c2a4e-8b3d-4c7a-9e21-0a5b7c9d1e3f",
    userId: "u1",
    mode: "image",
  });
  assertEquals(only(admin.calls).payload, {
    id: "6f1c2a4e-8b3d-4c7a-9e21-0a5b7c9d1e3f",
    user_id: "u1",
    mode: "image",
  });
});

Deno.test("start rejects a generation id that is already taken", async () => {
  const log = supabaseGenerationLog(
    fakeAdmin({ message: "duplicate key value", code: "23505" }).client,
  );
  await assertRejects(
    () =>
      log.start({
        id: "6f1c2a4e-8b3d-4c7a-9e21-0a5b7c9d1e3f",
        userId: "u1",
        mode: "image",
      }),
    ValidationError,
    "generationId",
  );
});

Deno.test("succeed stores the result key and completes the row", async () => {
  const admin = fakeAdmin();
  await supabaseGenerationLog(admin.client).succeed(
    "g1",
    "u1/tryon-1.png",
  );
  const call = only(admin.calls);
  assertEquals(call.op, "update");
  assertEquals(call.eq, ["id", "g1"]);
  assertEquals(call.payload?.status, "succeeded");
  assertEquals(call.payload?.result_key, "u1/tryon-1.png");
  assertEquals(typeof call.payload?.completed_at, "string");
});

Deno.test("fail stores the error message and completes the row", async () => {
  const admin = fakeAdmin();
  await supabaseGenerationLog(admin.client).fail("g1", "image generation returned null");
  const call = only(admin.calls);
  assertEquals(call.eq, ["id", "g1"]);
  assertEquals(call.payload?.status, "failed");
  assertEquals(
    call.payload?.error_message,
    "image generation returned null",
  );
  assertEquals(typeof call.payload?.completed_at, "string");
});

Deno.test("each operation surfaces a database error", async () => {
  const log = supabaseGenerationLog(
    fakeAdmin({ message: "permission denied" }).client,
  );
  await assertRejects(
    () => log.start({ userId: "u1", mode: "image" }),
    Error,
    "permission denied",
  );
  await assertRejects(() => log.succeed("g1", "k"), Error, "permission denied");
  await assertRejects(() => log.fail("g1", "busy"), Error, "permission denied");
});
