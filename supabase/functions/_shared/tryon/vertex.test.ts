import { assertEquals, assertRejects, assertStringIncludes } from "@std/assert";
import { ServiceBusyError } from "../errors.ts";
import { GenerationFailedError } from "./errors.ts";
import { generateTryonImage, generateTryonVideo } from "./vertex.ts";

const IMAGE_MODEL = "gemini-3.1-flash-image";
const PRO_MODEL = "gemini-3-pro-image";
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
  Deno.env.set("TRYON_MODEL", IMAGE_MODEL);
  Deno.env.set("TRYON_MODEL_EXPERIMENTAL", PRO_MODEL);
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
    const answer = respond(url, body);
    return Promise.resolve(
      answer instanceof Response ? answer : Response.json(answer),
    );
  }) as typeof fetch;
  return { captured, restore: () => (globalThis.fetch = original) };
}

function modelOf({ url }: Captured): string {
  return url.split("/models/")[1].split(":")[0];
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

Deno.test("generateTryonImage asks for a 2K JPEG portrait", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(() => ({
    candidates: [{
      content: {
        role: "model",
        parts: [{ inlineData: { mimeType: "image/png", data: IMAGE_BASE64 } }],
      },
      finishReason: "STOP",
    }],
  }));
  try {
    const image = await generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]);

    assertEquals(image, IMAGE_BASE64);
    assertEquals(captured.length, 1);
    const [{ url, body }] = captured;
    assertStringIncludes(url, `/models/${IMAGE_MODEL}:generateContent`);
    const config = body.generationConfig as Record<string, unknown>;
    assertEquals(config.responseModalities, ["IMAGE"]);
    assertEquals(config.imageConfig, {
      aspectRatio: "9:16",
      imageSize: "2K",
      imageOutputOptions: { mimeType: "image/jpeg", compressionQuality: 95 },
    });
  } finally {
    restore();
  }
});

// A quota refusal that asks for no wait, so the test observes the attempt
// count without sitting through the backoff.
function quotaRefusal(): Response {
  return Response.json(
    { error: { code: 429, status: "RESOURCE_EXHAUSTED" } },
    { status: 429, headers: { "retry-after": "0" } },
  );
}

Deno.test("generateTryonImage asks the standard model once, then retries the fallback enough to reach the next minute", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(quotaRefusal);
  try {
    await assertRejects(
      () => generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]),
      ServiceBusyError,
    );
    assertEquals(captured.map(modelOf), [
      IMAGE_MODEL,
      ...Array(6).fill(PRO_MODEL),
    ]);
  } finally {
    restore();
  }
});

Deno.test("generateTryonVideo retries a quota refusal enough to reach the next minute", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(quotaRefusal);
  try {
    await assertRejects(
      () => generateTryonVideo(IMAGE_BASE64),
      ServiceBusyError,
    );
    assertEquals(captured.length, 6);
  } finally {
    restore();
  }
});

function imageAnswer(): unknown {
  return {
    candidates: [{
      content: {
        role: "model",
        parts: [{ inlineData: { mimeType: "image/png", data: IMAGE_BASE64 } }],
      },
      finishReason: "STOP",
    }],
  };
}

function badRequest(): Response {
  return Response.json({ error: { code: 400, status: "INVALID_ARGUMENT" } }, {
    status: 400,
  });
}

Deno.test("generateTryonImage falls back to the experimental model when the standard one refuses for quota", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch((url) =>
    url.includes(`/models/${IMAGE_MODEL}:`) ? quotaRefusal() : imageAnswer()
  );
  try {
    const image = await generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]);

    assertEquals(image, IMAGE_BASE64);
    assertEquals(captured.map(modelOf), [IMAGE_MODEL, PRO_MODEL]);
  } finally {
    restore();
  }
});

Deno.test("generateTryonImage falls back to the experimental model when the standard one answers without an image", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch((url) =>
    url.includes(`/models/${IMAGE_MODEL}:`)
      ? {
        candidates: [{
          content: { role: "model", parts: [{ text: "No image this time." }] },
          finishReason: "STOP",
        }],
      }
      : imageAnswer()
  );
  try {
    const image = await generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]);

    assertEquals(image, IMAGE_BASE64);
    assertEquals(captured.map(modelOf), [IMAGE_MODEL, PRO_MODEL]);
  } finally {
    restore();
  }
});

Deno.test("generateTryonImage falls back to the experimental model on a failure that is not about capacity", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch((url) =>
    url.includes(`/models/${IMAGE_MODEL}:`) ? badRequest() : imageAnswer()
  );
  try {
    const image = await generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]);

    assertEquals(image, IMAGE_BASE64);
    assertEquals(captured.map(modelOf), [IMAGE_MODEL, PRO_MODEL]);
  } finally {
    restore();
  }
});

Deno.test("generateTryonImage stops at a fallback failure that is not about capacity", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(badRequest);
  try {
    await assertRejects(() =>
      generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]])
    );
    assertEquals(captured.map(modelOf), [IMAGE_MODEL, PRO_MODEL]);
  } finally {
    restore();
  }
});

Deno.test("generateTryonImage logs why the standard model was passed over", async () => {
  await installServiceAccount();
  const { restore } = stubFetch((url) =>
    url.includes(`/models/${IMAGE_MODEL}:`) ? quotaRefusal() : imageAnswer()
  );
  const logged: string[] = [];
  const { info, warn } = console;
  console.info = (message: string) => logged.push(message);
  console.warn = (message: string) => logged.push(message);
  try {
    await generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]]);

    assertEquals(
      logged
        .filter((line) => line.startsWith("vertex:"))
        .map((line) => line.split(":").slice(0, 2).join(":")),
      [
        `vertex: model=${IMAGE_MODEL} region=global`,
        `vertex: model=${IMAGE_MODEL} failed`,
        `vertex: model=${PRO_MODEL} region=global`,
      ],
    );
  } finally {
    console.info = info;
    console.warn = warn;
    restore();
  }
});

Deno.test("generateTryonImage keeps the experimental engine on its one model", async () => {
  await installServiceAccount();
  const { captured, restore } = stubFetch(quotaRefusal);
  try {
    await assertRejects(
      () =>
        generateTryonImage(IMAGE_BASE64, [[IMAGE_BASE64]], {
          engine: "experimental",
        }),
      ServiceBusyError,
    );
    assertEquals(captured.length, 6);
    assertEquals(new Set(captured.map(modelOf)), new Set([PRO_MODEL]));
  } finally {
    restore();
  }
});
