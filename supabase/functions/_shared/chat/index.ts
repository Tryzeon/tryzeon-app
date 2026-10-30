export { runChatAgent, type RunChatAgentDeps } from "./run.ts";
export { ANSWER_LIMITS, windowHistory } from "./logic.ts";
export { CHAT_RATE_LIMIT, checkChatRateLimit } from "./rate-limit.ts";
export type {
  AgentAnswer,
  AgentRequest,
  AgentRunner,
  AnswerColorLoader,
  AnswerHydrator,
  AnswerItems,
  AnswerRows,
  ContextLoader,
  ProductColorNames,
} from "./types.ts";

export { LIMITS } from "./types.ts";
export type {
  AnswerBlock,
  ChatContext,
  ChatEvent,
  ChatMessage,
  ChatParams,
  ChatResult,
  ChatRole,
  ContentBlock,
  ItemRef,
  OutfitRef,
  PickRef,
  ProductItemRef,
  WardrobeItemRef,
} from "./types.ts";

export {
  classifyCoreError,
  CORE_ERROR_CODE,
  type CoreErrorInfo,
} from "../errors.ts";
export { parseJsonObject, ValidationError } from "../validation.ts";
