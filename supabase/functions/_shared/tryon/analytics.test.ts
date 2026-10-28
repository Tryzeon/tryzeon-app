import { assertEquals, assertRejects } from "@std/assert";
import { supabaseTryonRecorder } from "./analytics.ts";
import type { RpcCall } from "../quota.testing.ts";
import type { DbClient } from "../supabase.ts";

function fakeAdmin(error: { message: string } | null = null) {
  const calls: RpcCall[] = [];
  const client = {
    rpc(fn: string, args: Record<string, unknown>) {
      calls.push({ fn, args });
      return Promise.resolve({ data: null, error });
    },
  } as unknown as DbClient;
  return { client, calls };
}

Deno.test("supabaseTryonRecorder logs every worn colour for the user in one call", async () => {
  const admin = fakeAdmin();
  await supabaseTryonRecorder(admin.client)("u1", [
    { productId: "p1", colorId: "c1" },
  ]);
  assertEquals(admin.calls, [{
    fn: "log_tryon_events",
    args: { p_user_id: "u1", p_worn: [{ product_id: "p1", color_id: "c1" }] },
  }]);
});

Deno.test("supabaseTryonRecorder surfaces an RPC error", async () => {
  const admin = fakeAdmin({ message: "permission denied" });
  await assertRejects(
    () =>
      supabaseTryonRecorder(admin.client)("u1", [{
        productId: "p1",
        colorId: "c1",
      }]),
    Error,
    "permission denied",
  );
});
