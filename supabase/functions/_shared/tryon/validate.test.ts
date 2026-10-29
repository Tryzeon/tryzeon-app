import { assertEquals, assertThrows } from "@std/assert";
import { validateTryonParams } from "./validate.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS, type TryonParams } from "./types.ts";

const validParams: TryonParams = {
  userId: "u1",
  garments: [{ images: [{ base64: "BBBB" }] }],
  mode: "image",
};

Deno.test("validateTryonParams accepts valid params", () => {
  validateTryonParams(validParams); // does not throw
});

Deno.test("validateTryonParams rejects an empty userId", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, userId: "" }),
    ValidationError,
    "userId",
  );
});

Deno.test("validateTryonParams rejects empty garments", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, garments: [] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects too many garments", () => {
  const g = { images: [{ base64: "X" }] };
  assertThrows(
    () => validateTryonParams({ ...validParams, garments: [g, g, g, g] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects too many images in a garment", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{
          images: [{ base64: "1" }, { base64: "2" }, { base64: "3" }, {
            base64: "4",
          }],
        }],
      }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects a garment image without bytes", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{ images: [{ base64: "" }] }],
      }),
    ValidationError,
    "garment image",
  );
});

Deno.test("validateTryonParams rejects an oversized garment image", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{
          images: [{ base64: "x".repeat(LIMITS.MAX_BASE64_LENGTH + 1) }],
        }],
      }),
    ValidationError,
    "too large",
  );
});

Deno.test("validateTryonParams accepts a garment image exactly at the limit", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [{ images: [{ base64: "x".repeat(LIMITS.MAX_BASE64_LENGTH) }] }],
  });
  assertEquals(
    (job.garments[0] as { images: { base64: string }[] }).images[0].base64
      .length,
    LIMITS.MAX_BASE64_LENGTH,
  );
});

Deno.test("validateTryonParams strips a garment detail a caller tried to set", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [
      { images: [{ base64: "B" }], detail: "smuggled" } as TryonParams[
        "garments"
      ][number],
    ],
  });
  assertEquals(job.garments, [{ images: [{ base64: "B" }] }]);
});

Deno.test("validateTryonParams accepts a product-ref garment", () => {
  validateTryonParams({
    ...validParams,
    garments: [{ productId: "33333333-3333-3333-3333-333333333333" }],
  }); // does not throw
});

Deno.test("validateTryonParams rejects an empty productId", () => {
  assertThrows(
    () =>
      validateTryonParams({ ...validParams, garments: [{ productId: "" }] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects a non-string productId with a productId error", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{ productId: 123 as unknown as string }],
      }),
    ValidationError,
    "productId",
  );
});

Deno.test("validateTryonParams rejects an invalid mode", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        mode: "gif" as unknown as TryonParams["mode"],
      }),
    ValidationError,
    "mode",
  );
});

Deno.test("validateTryonParams rejects an overlong scenePrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        scenePrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "scenePrompt",
  );
});

Deno.test("validateTryonParams rejects an overlong transitionPrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        mode: "video",
        transitionPrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "transitionPrompt",
  );
});

Deno.test("validateTryonParams returns params with sources narrowed", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [{ images: [{ base64: "BBBB" }] }],
    scenePrompt: "beach",
  });
  assertEquals(job.garments, [{ images: [{ base64: "BBBB" }] }]);
  assertEquals(job.userId, "u1");
  assertEquals(job.mode, "image");
  assertEquals(job.scenePrompt, "beach");
});

Deno.test("validateTryonParams returns a product-ref garment as just its id", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [
      {
        productId: "33333333-3333-3333-3333-333333333333",
        images: [{ base64: "IGNORED" }],
      } as unknown as TryonParams["garments"][number],
    ],
  });
  assertEquals(job.garments, [
    { productId: "33333333-3333-3333-3333-333333333333" },
  ]);
});

Deno.test("validateTryonParams accepts a wardrobe ref", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [{ wardrobeItemId: "44444444-4444-4444-4444-444444444444" }],
  });
  assertEquals(job.garments, [
    { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
  ]);
});

Deno.test("validateTryonParams rejects an empty wardrobeItemId", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{ wardrobeItemId: "" }],
      }),
    ValidationError,
    "wardrobeItemId",
  );
});

Deno.test("validateTryonParams keeps a garment's sizeId", () => {
  const params = validateTryonParams({
    userId: "u1",
    garments: [{ productId: "p1", sizeId: "s1" }],
    mode: "image",
  });

  assertEquals(params.garments[0], { productId: "p1", sizeId: "s1" });
});

Deno.test("validateTryonParams omits sizeId when the caller sent none", () => {
  const params = validateTryonParams({
    userId: "u1",
    garments: [{ productId: "p1" }],
    mode: "image",
  });

  assertEquals(params.garments[0], { productId: "p1" });
});

Deno.test("validateTryonParams rejects a non-string sizeId", () => {
  assertThrows(
    () =>
      validateTryonParams({
        userId: "u1",
        garments: [
          {
            productId: "p1",
            sizeId: 7,
          } as unknown as TryonParams["garments"][number],
        ],
        mode: "image",
      }),
    ValidationError,
    "garment sizeId",
  );
});

Deno.test("validateTryonParams a product garment keeps its colorId", () => {
  const params = validateTryonParams({
    userId: "u1",
    garments: [{ productId: "p1", colorId: "c1" }],
    mode: "image",
  });

  assertEquals(params.garments[0], { productId: "p1", colorId: "c1" });
});

Deno.test("validateTryonParams a non-string colorId is rejected", () => {
  assertThrows(
    () =>
      validateTryonParams({
        userId: "u1",
        garments: [
          {
            productId: "p1",
            colorId: 1,
          } as unknown as TryonParams["garments"][number],
        ],
        mode: "image",
      }),
    ValidationError,
    "garment colorId",
  );
});

Deno.test("validateTryonParams keeps the transitionPrompt on a video job", () => {
  const job = validateTryonParams({
    ...validParams,
    mode: "video",
    transitionPrompt: "spin",
  });
  assertEquals(job.transitionPrompt, "spin");
});

Deno.test("validateTryonParams rejects an overlong stylingPrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        stylingPrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "stylingPrompt",
  );
});

Deno.test("validateTryonParams keeps the stylingPrompt on a generate job", () => {
  const job = validateTryonParams({
    ...validParams,
    stylingPrompt: "tucked into the waistband",
  });
  assertEquals(job.stylingPrompt, "tucked into the waistband");
});

Deno.test("validateTryonParams defaults a missing engine to standard", () => {
  assertEquals(validateTryonParams(validParams).engine, "standard");
});

Deno.test("validateTryonParams keeps the experimental engine on a generate job", () => {
  const job = validateTryonParams({ ...validParams, engine: "experimental" });
  assertEquals(job.engine, "experimental");
});

Deno.test("validateTryonParams falls back to standard on an unknown engine", () => {
  const job = validateTryonParams({
    ...validParams,
    engine: "turbo" as TryonParams["engine"],
  });
  assertEquals(job.engine, "standard");
});

Deno.test("validateTryonParams falls back to standard on a non-string engine", () => {
  const job = validateTryonParams({
    ...validParams,
    engine: 7 as unknown as TryonParams["engine"],
  });
  assertEquals(job.engine, "standard");
});

Deno.test("validateTryonParams keeps a uuid generation id", () => {
  const id = "6f1c2a4e-8b3d-4c7a-9e21-0a5b7c9d1e3f";
  assertEquals(
    validateTryonParams({ ...validParams, generationId: id }).generationId,
    id,
  );
});

Deno.test("validateTryonParams leaves a missing generation id to the database", () => {
  assertEquals(validateTryonParams(validParams).generationId, undefined);
});

Deno.test("validateTryonParams rejects a generation id that is not a uuid", () => {
  for (const generationId of ["", "g1", 42]) {
    assertThrows(
      () =>
        validateTryonParams({
          ...validParams,
          generationId: generationId as string,
        }),
      ValidationError,
      "generationId",
    );
  }
});
