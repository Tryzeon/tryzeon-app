/**
 * Vertex meters generation per model per minute, and this project's grant for
 * image generation is 2 requests a minute — a third try-on in the same minute
 * is refused with 429 (KAN-51). The SDK backs off 2, 4, 8, 16, 32 s between
 * attempts, so five retries wait 62 s in all: the last attempt always falls in
 * the next minute's window. A sixth would wait 64 s more and overrun the
 * platform's 150 s request limit.
 */
export const QUOTA_WINDOW_RETRIES = 5;
