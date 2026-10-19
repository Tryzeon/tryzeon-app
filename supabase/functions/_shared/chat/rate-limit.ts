import { checkWindowedRateLimit, type WindowedLimit } from "../rate-limit.ts";

export const CHAT_RATE_LIMIT: WindowedLimit = { perMinute: 15, perDay: 50 };

export const checkChatRateLimit = (userId: string) =>
  checkWindowedRateLimit(userId, "chat", CHAT_RATE_LIMIT);
