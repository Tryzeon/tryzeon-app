import { RateLimitedError } from "../errors.ts";
import { checkChatRateLimit } from "./rate-limit.ts";
import { buildChatContext } from "./context.ts";
import { supabaseAnswerRows } from "./hydrate.ts";
import { answerBlocksOf, suggestionsOf } from "./logic.ts";
import { validateChatParams } from "./validate.ts";
import { runVertexAgent } from "./vertex.ts";
import type {
  AgentRunner,
  AnswerBlock,
  AnswerHydrator,
  AnswerItems,
  AnswerRows,
  ChatMessage,
  ChatParams,
  ChatResult,
  ContextLoader,
} from "./types.ts";
import type { DbClient } from "../supabase.ts";

const FALLBACK_TEXT = "抱歉，我這次沒能幫你找到，可以再多說一點你的需求嗎？";

const NO_ROWS: AnswerRows = { products: new Map(), wardrobe: new Map() };

export interface RunChatAgentDeps {
  checkLimit?: (userId: string) => Promise<boolean>;
  loadContext?: ContextLoader;
  runAgent?: AgentRunner;
  hydrate?: AnswerHydrator;
}

/**
 * Single chat entry point: validate -> rate limit -> ground -> agent loop ->
 * hydrate.
 *
 * The stored answer is the model's output read by `answerBlocksOf`, so every
 * surface renders the same rows; hydration only builds the render rows for the
 * ids they name, and a row that came back missing is each surface's to skip.
 *
 * One client, and it is the caller's own: grounding, the tool searches and
 * hydration all go through it, so an adapter with a session (the app) has RLS
 * bounding what a turn can read. An adapter without one (LINE) passes its admin
 * client, and on that path the `.eq("user_id", …)` filters in `tools.ts` and
 * `hydrate.ts` are the only thing scoping a wardrobe read.
 *
 * An unusable structured output is not a throw — the answer degrades to a
 * single fallback text block. A failure to read the referenced rows is a throw:
 * that is a server fault, and reporting it as "I couldn't find anything" would
 * be a lie.
 */
export async function runChatAgent(
  client: DbClient,
  params: ChatParams,
  deps: RunChatAgentDeps = {},
): Promise<ChatResult> {
  // Everything below runs on `turn`, never on the raw `params`: the guard is
  // also the normalizer, so the run cannot read a message the guard did not see.
  const turn = validateChatParams(params);

  const loadContext = deps.loadContext ?? buildChatContext;
  const runAgent = deps.runAgent ?? runVertexAgent;
  const hydrate = deps.hydrate ?? supabaseAnswerRows;

  const checkLimit = deps.checkLimit ?? checkChatRateLimit;
  if (!await checkLimit(turn.userId)) {
    throw new RateLimitedError();
  }

  const context = await loadContext(client, turn.userId);

  const { output, rounds } = await runAgent({
    client,
    userId: turn.userId,
    context,
    messages: turn.messages,
    onEvent: turn.onEvent,
  });

  const blocks = answerBlocksOf(output?.blocks);
  const content: AnswerBlock[] = blocks.length > 0
    ? blocks
    : [{ type: "text", text: FALLBACK_TEXT }];
  const rows = blocks.length > 0
    ? await hydrate(client, turn.userId, content)
    : NO_ROWS;
  const answer: ChatMessage = { role: "assistant", content };
  const items: AnswerItems = {
    products: Object.fromEntries(rows.products),
    wardrobe: Object.fromEntries(rows.wardrobe),
  };

  const suggestions = blocks.length > 0
    ? suggestionsOf(output?.suggestions)
    : [];

  return { messages: [...rounds, answer], answer: content, items, suggestions };
}
