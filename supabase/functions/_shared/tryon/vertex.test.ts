import { assertEquals, assertRejects, assertStringIncludes } from "@std/assert";
import { GenerationFailedError } from "./errors.ts";
import { generateTryonVideo } from "./vertex.ts";

const STANDARD_MODEL = "gemini-omni-1.1-flash-preview";
const EXPERIMENTAL_MODEL = "veo-3.1-fast-generate-001";
const VIDEO_BASE64 = btoa("mp4-bytes");
const IMAGE_BASE64 = btoa("png-bytes");

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
  Deno.env.set("VIDEO_MODEL", STANDARD_MODEL);
  Deno.env.set("VIDEO_MODEL_EXPERIMENTAL", EXPERIMENTAL_MODEL);
}

interface Part {
  type: string;
  text?: string;
  data?: string;
  mime_type?: string;
}

interface Captured {
  url: string;
  body: Record<string, unknown>;
}

function stubFetch(
  respond: (url: string, body: Record<string, unknown>) => unknown,
): { captured: Captured[]; restore: () => void } {
  const captured: Captured[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = input instanceof Request ? input.url : input.toString();
    if (url.startsWith("https://oauth2.googleapis.com/token")) {
      return Promise.resolve(Response.json({ access_token: "token" }));
    }
    const body = JSON.parse(init?.body as string);
    captured.push({ url, body });
    return Promise.resolve(Response.json(respond(url, body)));
  }) as typeof fetch;
  return { captured, restore: () => (globalThis.fetch = original) };
}

function interaction(content: unknown[]) {
  return {
    id: "int-1",
    model: STANDARD_MODEL,
    status: "completed",
    role: "model",
    object: "interaction",
    steps: [{ type: "model_output", content }],
  };
}

Deno.test("generateTryonVideo runs the standard engine through the Interactions API", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(() =>
    interaction([{
      type: "video",
      data: VIDEO_BASE64,
      mime_type: "video/mp4",
    }])
  );
  try {
    const bytes = await generateTryonVideo(IMAGE_BASE64, {
      transitionPrompt: "slow dolly in",
    });

    assertEquals(new TextDecoder().decode(bytes), "mp4-bytes");
    assertEquals(captured.length, 1);
    const [{ url, body }] = captured;
    assertStringIncludes(url, "/locations/global/interactions");
    assertEquals(body.model, STANDARD_MODEL);
    assertEquals(body.response_format, [{
      type: "video",
      aspect_ratio: "9:16",
    }]);

    const [turn] = body.input as { type: string; content: Part[] }[];
    assertEquals(turn.type, "user_input");
    const image = turn.content.find((part) => part.type === "image");
    assertEquals(image?.data, IMAGE_BASE64);
    assertEquals(image?.mime_type, "image/jpeg");
    const text = turn.content.find((part) => part.type === "text");
    assertStringIncludes(
      text?.text ?? "",
      "Camera and transition style: slow dolly in.",
    );
  } finally {
    restore();
  }
});

Deno.test("generateTryonVideo fails when the interaction carries no video", async () => {
  await installServiceAccount();
  const { restore } = stubFetch(() =>
    interaction([{ type: "text", text: "I cannot make that video." }])
  );
  try {
    await assertRejects(
      () => generateTryonVideo(IMAGE_BASE64),
      GenerationFailedError,
      "No video in Vertex response",
    );
  } finally {
    restore();
  }
});

Deno.test("generateTryonVideo keeps the experimental engine on Veo", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch((url) =>
    url.endsWith(":predictLongRunning") ? { name: "operations/op-1" } : {
      name: "operations/op-1",
      done: true,
      response: {
        videos: [{ bytesBase64Encoded: VIDEO_BASE64, mimeType: "video/mp4" }],
      },
    }
  );
  try {
    const bytes = await generateTryonVideo(IMAGE_BASE64, {
      engine: "experimental",
    });

    assertEquals(new TextDecoder().decode(bytes), "mp4-bytes");
    assertStringIncludes(
      captured[0].url,
      `/models/${EXPERIMENTAL_MODEL}:predictLongRunning`,
    );
  } finally {
    restore();
  }
});
