import { assertEquals, assertRejects } from "@std/assert";
import { runTryonJob } from "./run.ts";
import {
  GenerationFailedError,
  MissingAvatarError,
  ValidationError,
} from "./errors.ts";
import { type DailyUsage, QuotaExceededError } from "../quota.ts";
import type { GarmentBrief } from "./prompt.ts";
import type {
  GenerationLog,
  QuotaFactory,
  TryonMode,
  TryonParams,
  TryonRecorder,
} from "./types.ts";
import type { DbClient } from "../supabase.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 1,
  chat_count: 0,
  video_count: 0,
};

// The job never reaches Supabase in these tests — quota and every resolver go
// through a port — so an empty object is an honest stand-in.
const client = {} as unknown as DbClient;

const ignoreTryons: TryonRecorder = () => Promise.resolve();

function fakeRecorder(fail = false) {
  const calls: Array<[string, string[]]> = [];
  const record: TryonRecorder = (userId, productIds) => {
    calls.push([userId, productIds]);
    return fail ? Promise.reject(new Error("analytics down")) : Promise.resolve();
  };
  return { record, calls };
}

function fakeGenerations(
  fail: { start?: boolean; succeed?: boolean; fail?: boolean } = {},
) {
  const calls: Array<{ op: string; args: unknown[] }> = [];
  const settle = (failed: boolean | undefined, op: string) =>
    failed ? Promise.reject(new Error(`${op} down`)) : Promise.resolve();
  const log: GenerationLog = {
    start(entry) {
      calls.push({ op: "start", args: [entry] });
      return settle(fail.start, "start").then(() => entry.id ?? "g1");
    },
    succeed(id, resultKey) {
      calls.push({ op: "succeed", args: [id, resultKey] });
      return settle(fail.succeed, "succeed");
    },
    fail(id, errorMessage) {
      calls.push({ op: "fail", args: [id, errorMessage] });
      return settle(fail.fail, "fail");
    },
  };
  return { log, calls };
}

const ignoreGenerations = fakeGenerations().log;

function fakeQuota(allowed = true) {
  const calls: string[] = [];
  const modes: TryonMode[] = [];
  const factory: QuotaFactory = (_userId, mode) => {
    modes.push(mode);
    return {
      charge() {
        calls.push("charge");
        return Promise.resolve({ allowed, usage: USAGE });
      },
      refund() {
        calls.push("refund");
        return Promise.resolve();
      },
    };
  };
  return { factory, calls, modes };
}

const imageParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AVATAR" },
  garments: [{ images: [{ base64: "GARMENT" }] }],
  mode: "image",
};

Deno.test("image mode uploads the generated image and does not call video", async () => {
  const quota = fakeQuota();
  let videoCalled = false;
  let uploadedKey = "";
  const result = await runTryonJob(client, imageParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: (_bytes, fileName) => {
      uploadedKey = fileName;
      return Promise.resolve("https://img/result.png");
    },
    generateVideo: () => {
      videoCalled = true;
      return Promise.resolve(new Uint8Array());
    },
    now: () => 123,
  });
  assertEquals(result, {
    kind: "image",
    imageUrl: "https://img/result.png",
    usage: USAGE,
  });
  assertEquals(uploadedKey, "u1/tryon-123.jpg");
  assertEquals(videoCalled, false);
  assertEquals(quota.calls, ["charge"]);
  assertEquals(quota.modes, ["image"]);
});

Deno.test("video mode uploads the generated video bytes, not an image", async () => {
  const quota = fakeQuota();
  let imageUploadCalled = false;
  let uploadedKey = "";
  let uploadedBytes: number[] = [];
  const result = await runTryonJob(
    client,
    { ...imageParams, mode: "video", transitionPrompt: "spin" },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      generate: () => Promise.resolve("GENERATEDB64"),
      upload: () => {
        imageUploadCalled = true;
        return Promise.resolve("https://img/should-not-happen.png");
      },
      generateVideo: () => Promise.resolve(new Uint8Array([1, 2, 3])),
      uploadVideo: (bytes, fileName) => {
        uploadedBytes = Array.from(bytes);
        uploadedKey = fileName;
        return Promise.resolve("https://vid/x.mp4");
      },
      now: () => 456,
    },
  );
  assertEquals(result, {
    kind: "video",
    videoUrl: "https://vid/x.mp4",
    usage: USAGE,
  });
  assertEquals(uploadedKey, "u1/tryon-456.mp4");
  assertEquals(uploadedBytes, [1, 2, 3]);
  assertEquals(imageUploadCalled, false);
});

Deno.test("video mode opens the quota counter for the video feature", async () => {
  const quota = fakeQuota();
  await runTryonJob(client, { ...imageParams, mode: "video" }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: () => Promise.resolve("GENERATEDB64"),
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(quota.modes, ["video"]);
});

Deno.test("video mode passes the transition prompt to the generator", async () => {
  const quota = fakeQuota();
  let seenPrompt: string | undefined;
  await runTryonJob(
    client,
    { ...imageParams, mode: "video", transitionPrompt: "spin" },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      generate: () => Promise.resolve("GENERATEDB64"),
      generateVideo: (_image, opts) => {
        seenPrompt = opts?.transitionPrompt;
        return Promise.resolve(new Uint8Array([1]));
      },
      uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
      now: () => 1,
    },
  );
  assertEquals(seenPrompt, "spin");
});

Deno.test("the job runs on validated params, not the raw input", async () => {
  const quota = fakeQuota();
  let seenAvatar = "";
  await runTryonJob(
    client,
    {
      ...imageParams,
      // A blank second key survives the wire but must not reach the loader.
      avatar: {
        base64: "AVATAR",
        path: "",
      } as unknown as TryonParams["avatar"],
    },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      generate: (avatarBase64) => {
        seenAvatar = avatarBase64;
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 1,
    },
  );
  assertEquals(seenAvatar, "AVATAR");
});

Deno.test("invalid params are rejected before quota is charged", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, { ...imageParams, garments: [] }, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
      }),
    Error,
  );
  assertEquals(quota.calls, []);
});

Deno.test("quota rejection throws QuotaExceededError with usage", async () => {
  const quota = fakeQuota(false);
  const err = await assertRejects(
    () => runTryonJob(client, imageParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
      }),
    QuotaExceededError,
  );
  assertEquals(err.usage, USAGE);
});

Deno.test("null generation throws GenerationFailedError and refunds quota", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a failed refund does not mask the original error", async () => {
  const quota: QuotaFactory = () => ({
    charge: () => Promise.resolve({ allowed: true, usage: USAGE }),
    refund: () => Promise.reject(new Error("refund exploded")),
  });

  const err = await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(err.message, "image generation returned null");
});

Deno.test("an omitted avatar is resolved from the user's profile", async () => {
  const quota = fakeQuota();
  const resolvedFor: string[] = [];
  let seenAvatar = "";
  await runTryonJob(client, { ...imageParams, avatar: undefined }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    resolveAvatar: (_admin, userId) => {
      resolvedFor.push(userId);
      // Base64 rather than a path: the loader would otherwise reach for storage
      // through the stand-in client.
      return Promise.resolve({ base64: "STORED" });
    },
    generate: (avatarBase64) => {
      seenAvatar = avatarBase64;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 123,
  });
  assertEquals(resolvedFor, ["u1"]);
  assertEquals(seenAvatar, "STORED");
});

Deno.test("an inline avatar override skips profile resolution", async () => {
  const quota = fakeQuota();
  let resolverCalled = false;
  let seenAvatar = "";
  await runTryonJob(client, imageParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    resolveAvatar: () => {
      resolverCalled = true;
      return Promise.resolve({ base64: "STORED" });
    },
    generate: (avatarBase64) => {
      seenAvatar = avatarBase64;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 123,
  });
  assertEquals(resolverCalled, false);
  assertEquals(seenAvatar, "AVATAR");
});

Deno.test("a user with no stored avatar is never charged", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, { ...imageParams, avatar: undefined }, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
        resolveAvatar: () => Promise.reject(new MissingAvatarError("none")),
        generate: () => Promise.resolve("GENERATEDB64"),
        upload: () => Promise.resolve("https://img/result.png"),
      }),
    MissingAvatarError,
  );
  // Not charge-then-refund: having no photo is a precondition, not a failed job.
  assertEquals(quota.calls, []);
});

Deno.test("product-ref garments are resolved before loading", async () => {
  const quota = fakeQuota();
  const seenGarmentB64: string[] = [];
  const result = await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [{ productId: "11111111-1111-1111-1111-111111111111" }],
      mode: "image",
    },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      resolveProduct: () =>
        Promise.resolve({
          images: [{ base64: "PRODUCTB64" }],
          detail: "Product: X",
        }),
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );
  assertEquals(result.kind, "image");
  assertEquals(seenGarmentB64, ["PRODUCTB64"]);
});

Deno.test("the resolvers' category and detail reach the generator, garment by garment", async () => {
  const quota = fakeQuota();
  let seenGarments: GarmentBrief[] | undefined;
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [
        { productId: "11111111-1111-1111-1111-111111111111" },
        { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
      ],
      mode: "image",
    },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      resolveProduct: () =>
        Promise.resolve({
          images: [{ base64: "P" }],
          category: "full_body",
          detail: "Product: X",
        }),
      resolveWardrobe: () => Promise.resolve({ images: [{ base64: "W" }] }),
      generate: (_avatar, _groups, opts) => {
        seenGarments = opts?.garments;
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );
  assertEquals(seenGarments, [
    { category: "full_body", detail: "Product: X" },
    { category: undefined, detail: undefined },
  ]);
});

Deno.test("product resolution failure refunds quota", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(
        client,
        {
          userId: "u1",
          avatar: { base64: "AVATAR" },
          garments: [{ productId: "bad" }],
          mode: "image",
        },
        {
          quota: quota.factory,
          recordTryon: ignoreTryons,
          generations: ignoreGenerations,
          resolveProduct: () => Promise.reject(new Error("no product")),
        },
      ),
    Error,
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a wardrobe ref is resolved with the job's own user id", async () => {
  const quota = fakeQuota();
  const seen: Array<[string, string]> = [];
  const seenGarmentB64: string[] = [];
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [{ wardrobeItemId: "44444444-4444-4444-4444-444444444444" }],
      mode: "image",
    },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      resolveWardrobe: (_admin, userId, itemId) => {
        // The user id comes from the job, never from the caller's garment —
        // that is what makes the ownership bound unforgeable.
        seen.push([userId, itemId]);
        return Promise.resolve({
          images: [{ base64: "WARDROBEB64" }],
          detail: "Category: top",
        });
      },
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );

  assertEquals(seen, [["u1", "44444444-4444-4444-4444-444444444444"]]);
  assertEquals(seenGarmentB64, ["WARDROBEB64"]);
});

Deno.test("each garment kind reaches its own resolver", async () => {
  const quota = fakeQuota();
  let productCalls = 0;
  let wardrobeCalls = 0;
  const seenGarmentB64: string[] = [];
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [
        { productId: "11111111-1111-1111-1111-111111111111" },
        { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
        { images: [{ base64: "RAWB64" }] },
      ],
      mode: "image",
    },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      resolveProduct: () => {
        productCalls++;
        return Promise.resolve({ images: [{ base64: "PRODUCTB64" }] });
      },
      resolveWardrobe: () => {
        wardrobeCalls++;
        return Promise.resolve({ images: [{ base64: "WARDROBEB64" }] });
      },
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );

  assertEquals([productCalls, wardrobeCalls], [1, 1]);
  assertEquals(seenGarmentB64, ["PRODUCTB64", "WARDROBEB64", "RAWB64"]);
});

Deno.test("runTryonJob hands the resolver the whole ref, size included", async () => {
  const quota = fakeQuota();
  let seenRef: unknown;

  await runTryonJob(client, {
    userId: "u1",
    avatar: { base64: "AVATAR" },
    garments: [{ productId: "p1", sizeId: "s1" }],
    mode: "image",
  }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    resolveProduct: (_admin, ref) => {
      seenRef = ref;
      return Promise.resolve({ images: [{ base64: "G" }] });
    },
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: () => Promise.resolve("https://img/result.png"),
  });

  assertEquals(seenRef, { productId: "p1", sizeId: "s1" });
});

const animateParams: TryonParams = {
  userId: "u1",
  garments: [],
  mode: "video",
  baseImage: { base64: "FINISHED" },
};

Deno.test("a baseImage job animates that image without generating one", async () => {
  const quota = fakeQuota();
  let generateCalled = false;
  let animatedImage = "";
  const result = await runTryonJob(client, animateParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: () => {
      generateCalled = true;
      return Promise.resolve("SHOULD-NOT-HAPPEN");
    },
    generateVideo: (image) => {
      animatedImage = image;
      return Promise.resolve(new Uint8Array([9]));
    },
    uploadVideo: () => Promise.resolve("https://vid/animated.mp4"),
    now: () => 789,
  });
  assertEquals(generateCalled, false);
  assertEquals(animatedImage, "FINISHED");
  assertEquals(result, {
    kind: "video",
    videoUrl: "https://vid/animated.mp4",
    usage: USAGE,
  });
});

Deno.test("a baseImage job never resolves an avatar", async () => {
  const quota = fakeQuota();
  let avatarResolved = false;
  await runTryonJob(client, animateParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    resolveAvatar: () => {
      avatarResolved = true;
      return Promise.reject(new MissingAvatarError("none"));
    },
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(avatarResolved, false);
});

Deno.test("a baseImage job resolves no garment", async () => {
  const quota = fakeQuota();
  let productResolved = false;
  let wardrobeResolved = false;
  await runTryonJob(client, animateParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    resolveProduct: () => {
      productResolved = true;
      return Promise.reject(new Error("should not happen"));
    },
    resolveWardrobe: () => {
      wardrobeResolved = true;
      return Promise.reject(new Error("should not happen"));
    },
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(productResolved, false);
  assertEquals(wardrobeResolved, false);
});

Deno.test("a baseImage job charges the video quota", async () => {
  const quota = fakeQuota();
  await runTryonJob(client, animateParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(quota.modes, ["video"]);
  assertEquals(quota.calls, ["charge"]);
});

Deno.test("a baseImage job refunds when animation fails", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, animateParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
        generateVideo: () => Promise.reject(new Error("vertex exploded")),
        uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
        now: () => 1,
      }),
    Error,
    "vertex exploded",
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a baseImage job is rejected before quota when the mode is image", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, { ...animateParams, mode: "image" }, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: ignoreGenerations,
      }),
    ValidationError,
  );
  assertEquals(quota.calls, []);
});

Deno.test("runTryonJob forwards the styling prompt to the image generator", async () => {
  const quota = fakeQuota();
  let seenStyling: string | undefined;

  await runTryonJob(client, {
    userId: "u1",
    avatar: { base64: "AVATAR" },
    garments: [{ images: [{ base64: "GARMENT" }] }],
    mode: "image",
    stylingPrompt: "tucked into the waistband",
  }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: (_avatar, _groups, opts) => {
      seenStyling = opts?.stylingPrompt;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
  });

  assertEquals(seenStyling, "tucked into the waistband");
});

Deno.test("runTryonJob forwards the engine to the image generator", async () => {
  const quota = fakeQuota();
  let seenEngine: string | undefined;

  await runTryonJob(client, { ...imageParams, engine: "experimental" }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: (_avatar, _groups, opts) => {
      seenEngine = opts?.engine;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
  });

  assertEquals(seenEngine, "experimental");
});

Deno.test("runTryonJob forwards the engine to the video generator", async () => {
  const quota = fakeQuota();
  let seenEngine: string | undefined;

  await runTryonJob(
    client,
    { ...imageParams, mode: "video", engine: "experimental" },
    {
      quota: quota.factory,
      recordTryon: ignoreTryons,
      generations: ignoreGenerations,
      generate: () => Promise.resolve("GENERATEDB64"),
      generateVideo: (_image, opts) => {
        seenEngine = opts?.engine;
        return Promise.resolve(new Uint8Array([1]));
      },
      uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    },
  );

  assertEquals(seenEngine, "experimental");
});

Deno.test("animate mode forwards the engine to the video generator", async () => {
  const quota = fakeQuota();
  let seenEngine: string | undefined;

  await runTryonJob(client, { ...animateParams, engine: "experimental" }, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generateVideo: (_image, opts) => {
      seenEngine = opts?.engine;
      return Promise.resolve(new Uint8Array([1]));
    },
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
  });

  assertEquals(seenEngine, "experimental");
});

Deno.test("runTryonJob sends the standard engine when the caller names none", async () => {
  const quota = fakeQuota();
  let seenEngine: string | undefined;

  await runTryonJob(client, imageParams, {
    quota: quota.factory,
    recordTryon: ignoreTryons,
    generations: ignoreGenerations,
    generate: (_avatar, _groups, opts) => {
      seenEngine = opts?.engine;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
  });

  assertEquals(seenEngine, "standard");
});

const PRODUCT_A = "11111111-1111-1111-1111-111111111111";
const PRODUCT_B = "22222222-2222-2222-2222-222222222222";

const productParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AVATAR" },
  garments: [
    { productId: PRODUCT_A },
    { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
    { productId: PRODUCT_B },
  ],
  mode: "image",
};

const resolveAny = () => Promise.resolve({ images: [{ base64: "G" }] });

Deno.test("a finished job records one try-on per product garment, for the job's user", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder();
  await runTryonJob(client, productParams, {
    quota: quota.factory,
    recordTryon: recorder.record,
    generations: ignoreGenerations,
    resolveProduct: resolveAny,
    resolveWardrobe: resolveAny,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 1,
  });
  assertEquals(recorder.calls, [["u1", [PRODUCT_A, PRODUCT_B]]]);
});

Deno.test("a video job records its product garments too", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder();
  await runTryonJob(client, { ...productParams, mode: "video" }, {
    quota: quota.factory,
    recordTryon: recorder.record,
    generations: ignoreGenerations,
    resolveProduct: resolveAny,
    resolveWardrobe: resolveAny,
    generate: () => Promise.resolve("GENERATEDB64"),
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(recorder.calls, [["u1", [PRODUCT_A, PRODUCT_B]]]);
});

Deno.test("a job with no product garments records nothing", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder();
  await runTryonJob(client, imageParams, {
    quota: quota.factory,
    recordTryon: recorder.record,
    generations: ignoreGenerations,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 1,
  });
  assertEquals(recorder.calls, []);
});

Deno.test("a job that fails records no try-on", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder();
  await assertRejects(
    () =>
      runTryonJob(client, productParams, {
        quota: quota.factory,
        recordTryon: recorder.record,
        generations: ignoreGenerations,
        resolveProduct: resolveAny,
        resolveWardrobe: resolveAny,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(recorder.calls, []);
});

Deno.test("a job whose upload fails records no try-on", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder();
  await assertRejects(
    () =>
      runTryonJob(client, productParams, {
        quota: quota.factory,
        recordTryon: recorder.record,
        generations: ignoreGenerations,
        resolveProduct: resolveAny,
        resolveWardrobe: resolveAny,
        generate: () => Promise.resolve("GENERATEDB64"),
        upload: () => Promise.reject(new Error("r2 down")),
      }),
    Error,
    "r2 down",
  );
  assertEquals(recorder.calls, []);
});

Deno.test("a recorder failure neither fails the job nor refunds it", async () => {
  const quota = fakeQuota();
  const recorder = fakeRecorder(true);
  const result = await runTryonJob(client, productParams, {
    quota: quota.factory,
    recordTryon: recorder.record,
    generations: ignoreGenerations,
    resolveProduct: resolveAny,
    resolveWardrobe: resolveAny,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 1,
  });
  assertEquals(result.kind, "image");
  assertEquals(recorder.calls.length, 1);
  assertEquals(quota.calls, ["charge"]);
});

Deno.test("a finished image job logs its generation under the client's id and the uploaded key", async () => {
  const generations = fakeGenerations();
  let uploadedKey = "";
  const id = "6f1c2a4e-8b3d-4c7a-9e21-0a5b7c9d1e3f";
  await runTryonJob(client, { ...imageParams, generationId: id }, {
    quota: fakeQuota().factory,
    recordTryon: ignoreTryons,
    generations: generations.log,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: (_bytes, fileName) => {
      uploadedKey = fileName;
      return Promise.resolve("https://img/result.png");
    },
    now: () => 1,
  });

  assertEquals(generations.calls, [
    { op: "start", args: [{ id, userId: "u1", mode: "image" }] },
    { op: "succeed", args: [id, uploadedKey] },
  ]);
});

Deno.test("a finished video job logs its generation under the uploaded video key", async () => {
  const generations = fakeGenerations();
  let uploadedKey = "";
  await runTryonJob(client, { ...imageParams, mode: "video" }, {
    quota: fakeQuota().factory,
    recordTryon: ignoreTryons,
    generations: generations.log,
    generate: () => Promise.resolve("GENERATEDB64"),
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: (_bytes, fileName) => {
      uploadedKey = fileName;
      return Promise.resolve("https://vid/result.mp4");
    },
    now: () => 1,
  });

  assertEquals(uploadedKey, "u1/tryon-1.mp4");
  assertEquals(generations.calls.at(-1), {
    op: "succeed",
    args: ["g1", "u1/tryon-1.mp4"],
  });
});

Deno.test("a quota rejection logs no generation", async () => {
  const generations = fakeGenerations();
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: fakeQuota(false).factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
      }),
    QuotaExceededError,
  );
  assertEquals(generations.calls, []);
});

Deno.test("a failed generation is marked with its error message and refunded", async () => {
  const quota = fakeQuota();
  const generations = fakeGenerations();
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(generations.calls.at(-1), {
    op: "fail",
    args: ["g1", "image generation returned null"],
  });
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("any failure is marked with its own message", async () => {
  const generations = fakeGenerations();
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: fakeQuota().factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
        generate: () => Promise.resolve("GENERATEDB64"),
        upload: () => Promise.reject(new Error("r2 down")),
      }),
    Error,
    "r2 down",
  );
  assertEquals(generations.calls.at(-1), {
    op: "fail",
    args: ["g1", "r2 down"],
  });
});

Deno.test("a thrown non-Error value is marked with its string form", async () => {
  const generations = fakeGenerations();
  await assertRejects(() =>
    runTryonJob(client, imageParams, {
      quota: fakeQuota().factory,
      recordTryon: ignoreTryons,
      generations: generations.log,
      generate: () => Promise.resolve("GENERATEDB64"),
      upload: () => Promise.reject("socket hang up"),
    })
  );
  assertEquals(generations.calls.at(-1), {
    op: "fail",
    args: ["g1", "socket hang up"],
  });
});

Deno.test("a generation that cannot be started fails the job before generating, and refunds", async () => {
  const quota = fakeQuota();
  const generations = fakeGenerations({ start: true });
  let generated = false;
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
        generate: () => {
          generated = true;
          return Promise.resolve("GENERATEDB64");
        },
      }),
    Error,
    "start down",
  );
  assertEquals(generated, false);
  assertEquals(generations.calls.map((c) => c.op), ["start"]);
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a generation that cannot be completed fails the job, is marked failed, and refunds", async () => {
  const quota = fakeQuota();
  const generations = fakeGenerations({ succeed: true });
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: quota.factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
        generate: () => Promise.resolve("GENERATEDB64"),
        upload: () => Promise.resolve("https://img/result.png"),
      }),
    Error,
    "succeed down",
  );
  assertEquals(generations.calls.map((c) => c.op), [
    "start",
    "succeed",
    "fail",
  ]);
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a failed fail-mark does not mask the original error", async () => {
  const generations = fakeGenerations({ fail: true });
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: fakeQuota().factory,
        recordTryon: ignoreTryons,
        generations: generations.log,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
});
