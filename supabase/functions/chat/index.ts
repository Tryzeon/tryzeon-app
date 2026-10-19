// Errors split by when they happen, not by what they are: a bad body is
// rejected with a status code, while anything raised after the 200 is committed
// arrives as an in-stream error frame. Both render from `classifyCoreError`.
import "@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { coreErrorResponse, jsonError } from "../_shared/http.ts";
import {
  classifyCoreError,
  runChatAgent,
} from "../_shared/chat/index.ts";
import { parseChatParams } from "./request.ts";
import { encodeEvent, errorEvent } from "./stream.ts";
import { makeCors } from "../_shared/cors.ts";

const cors = makeCors({ methods: "POST" });

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return cors.wrap(errorResponse);

    const params = parseChatParams(await req.text(), user!.id);
    // The turn runs on the requester's own client, so RLS bounds what its
    // grounding, searches and hydration can read.

    const stream = new ReadableStream({
      async start(controller) {
        const send = (ev: Record<string, unknown>) => controller.enqueue(encodeEvent(ev));
        try {
          // The client stores `messages` as sent rather than rebuilding the
          // turn from the tool events, which only drive its progress display.
          const { messages, items } = await runChatAgent(
            userClient!,
            { ...params, onEvent: send },
          );
          send({ type: "done", messages, items });
        } catch (err) {
          send(errorEvent(err));
        } finally {
          controller.close();
        }
      },
    });

    return cors.wrap(new Response(stream, {
      headers: {
        "Content-Type": "application/x-ndjson",
        "Cache-Control": "no-cache",
      },
    }));
  } catch (err) {
    const info = classifyCoreError(err);
    if (info) return cors.wrap(coreErrorResponse(info));
    console.error("Unexpected error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
