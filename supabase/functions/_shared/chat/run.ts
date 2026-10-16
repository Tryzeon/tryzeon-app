import { QuotaExceededError } from "../quota.ts";
import { buildChatContext } from "./context.ts";
import { supabaseAnswerRows } from "./hydrate.ts";
import { asRecord } from "../validation.ts";
import { validateChatParams } from "./validate.ts";
import { runVertexAgent } from "./vertex.ts";
import type {
  AgentRunner,
  AnswerHydrator,
  AnswerItems,
  AnswerRows,
  ChatMessage,
  ChatParams,
  ChatQuotaFactory,
  ChatResult,
  ContentBlock,
  ContextLoader,
} from "./types.ts";
import type { DbClient } from "../supabase.ts";

const FALLBACK_TEXT = "抱歉，我這次沒能幫你找到，可以再多說一點你的需求嗎？";

const NO_ROWS: AnswerRows = { products: new Map(), wardrobe: new Map() };

export interface RunChatAgentDeps {
  quota: ChatQuotaFactory;
  loadContext?: ContextLoader;
  runAgent?: AgentRunner;
  hydrate?: AnswerHydrator;
}

/**
 * Single chat entry point: validate -> quota -> ground -> agent loop ->
 * hydrate.
 *
 * The stored answer is the model's output blocks verbatim; hydration only
 * builds the render rows for the ids they name, and what is renderable is each
 * client's call.
 *
 * One client, and it is the caller's own: grounding, the tool searches and
 * hydration all go through it, so an adapter with a session (the app) has RLS
 * bounding what a turn can read. An adapter without one (LINE) passes its admin
 * client, and on that path the `.eq("user_id", …)` filters in `tools.ts` and
 * `hydrate.ts` are the only thing scoping a wardrobe read.
 *
 * Quota is charged up front and refunded if anything after it throws. An
 * unusable structured output is not a throw — the model ran, so quota stays
 * spent and the answer degrades to a single fallback text block. A failure to
 * read the referenced rows is a throw: that is a server fault, and reporting it
 * as "I couldn't find anything" would charge the caller for a lie.
 */
export async function runChatAgent(
  client: DbClient,
  params: ChatParams,
  deps: RunChatAgentDeps,
): Promise<ChatResult> {
  // Everything below runs on `turn`, never on the raw `params`: the guard is
  // also the normalizer, so the run cannot read a message the guard did not see.
  const turn = validateChatParams(params);

  const loadContext = deps.loadContext ?? buildChatContext;
  const runAgent = deps.runAgent ?? runVertexAgent;
  const hydrate = deps.hydrate ?? supabaseAnswerRows;

  const quota = deps.quota(turn.userId);
  const { allowed, usage } = await quota.charge();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const context = await loadContext(client, turn.userId);

    const { output, rounds } = await runAgent({
      client,
      userId: turn.userId,
      context,
      messages: turn.messages,
      onEvent: turn.onEvent,
    });

    const blocks: ContentBlock[] = Array.isArray(output?.blocks)
      ? output.blocks.filter((entry: unknown) => asRecord(entry) !== null)
      : [];
    const content: ContentBlock[] = blocks.length > 0
      ? blocks
      : [{ type: "text", text: FALLBACK_TEXT }];
    const rows = blocks.length > 0 ? await hydrate(client, turn.userId, content) : NO_ROWS;
    const answer: ChatMessage = { role: "assistant", content };
    const items: AnswerItems = {
      products: Object.fromEntries(rows.products),
      wardrobe: Object.fromEntries(rows.wardrobe),
    };

    return { messages: [...rounds, answer], items, usage };
  } catch (err) {
    // Refund is best-effort: a failure here must not replace the error that
    // actually caused the turn to fail, or callers would report the wrong thing.
    try {
      await quota.refund();
    } catch (refundErr) {
      console.error("chat quota refund failed:", refundErr);
    }
    throw err;
  }
}
