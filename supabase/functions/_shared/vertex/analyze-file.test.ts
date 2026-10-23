import { assertEquals, assertRejects } from "@std/assert";
import { ServiceBusyError } from "../errors.ts";
import { analyzeFile } from "./analyze-file.ts";

const ARGS = {
  prompt: "Label this.",
  file: { mediaType: "image/jpeg", data: btoa("jpeg-bytes") },
  deadlineMs: 15_000,
  schema: {
    type: "object",
    properties: { name: { type: "string" } },
    required: ["name"],
  },
};

function pem(der: ArrayBuffer): string {
  const body = btoa(String.fromCharCode(...new Uint8Array(der)))
    .match(/.{1,64}/g)!
    .join("\n");
  return `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----\n`;
}

// The edge provider signs a real JWT before it ever talks to Vertex, so the
// stubbed credential needs a key Web Crypto will import.
async function installServiceAccount() {
  const { privateKey } = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const der = await crypto.subtle.exportKey("pkcs8", privateKey);
  Deno.env.set(
    "GOOGLE_SERVICE_ACCOUNT",
    JSON.stringify({
      project_id: "tryzeon-test",
      client_email: "vertex@tryzeon-test.iam.gserviceaccount.com",
      private_key: pem(der),
    }),
  );
  Deno.env.set("ANALYSIS_MODEL", "test-analysis-model");
}

function stubFetch(
  respond: (
    body: Record<string, unknown>,
    signal?: AbortSignal | null,
  ) => Promise<Response>,
): { captured: Record<string, unknown>[]; restore: () => void } {
  const captured: Record<string, unknown>[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : input.toString();
    if (url.startsWith("https://oauth2.googleapis.com/token")) {
      return Promise.resolve(Response.json({ access_token: "token" }));
    }
    const body = JSON.parse(init?.body as string);
    captured.push(body);
    return respond(body, init?.signal);
  }) as typeof fetch;
  return { captured, restore: () => (globalThis.fetch = original) };
}

const answer = (text: string) =>
  Promise.resolve(Response.json({
    candidates: [{
      content: { role: "model", parts: [{ text }] },
      finishReason: "STOP",
    }],
  }));

Deno.test("analyzeFile asks for minimal thinking", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(() => answer('{"name":"白色襯衫"}'));
  try {
    assertEquals(await analyzeFile(ARGS), { name: "白色襯衫" });
    const config = captured[0].generationConfig as { thinkingConfig?: unknown };
    assertEquals(config.thinkingConfig, { thinkingLevel: "minimal" });
  } finally {
    restore();
  }
});

Deno.test("analyzeFile reports a stall past its deadline as busy", async () => {
  await installServiceAccount();
  const { restore } = stubFetch((_, signal) =>
    new Promise((_, reject) =>
      signal?.addEventListener("abort", () => reject(signal.reason))
    )
  );
  try {
    await assertRejects(
      () => analyzeFile({ ...ARGS, deadlineMs: 50 }),
      ServiceBusyError,
    );
  } finally {
    restore();
  }
});

Deno.test("analyzeFile reports a capacity refusal as busy", async () => {
  await installServiceAccount();
  const { restore } = stubFetch(() =>
    Promise.resolve(Response.json(
      { error: { code: 503, message: "overloaded", status: "UNAVAILABLE" } },
      { status: 503 },
    ))
  );
  try {
    await assertRejects(() => analyzeFile(ARGS), ServiceBusyError);
  } finally {
    restore();
  }
});

Deno.test("analyzeFile passes on a failure that is not about capacity", async () => {
  await installServiceAccount();
  const { restore } = stubFetch(() => answer("not json"));
  try {
    const err = await assertRejects(() => analyzeFile(ARGS));
    assertEquals(err instanceof ServiceBusyError, false);
  } finally {
    restore();
  }
});
