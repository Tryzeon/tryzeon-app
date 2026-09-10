import { assertEquals, assertStringIncludes } from "@std/assert";
import { buildGarmentFitDetail, type ProductSizeFit } from "./fit.ts";
import { LIMITS } from "./types.ts";

function size(
  name: string,
  garment: ProductSizeFit["garment_measurements"],
  ranges: ProductSizeFit["body_measurement_ranges"] = null,
): ProductSizeFit {
  return {
    name,
    garment_measurements: garment,
    body_measurement_ranges: ranges,
  };
}

Deno.test("buildGarmentFitDetail describes a circumference with its ease and adjective", () => {
  const detail = buildGarmentFitDetail(
    size("M", { chest_circumference: 104 }),
    { chest: 92 },
  );
  assertEquals(
    detail,
    "size M: chest 104cm on a 92cm chest (+12cm — fitted, follows the body with a little room)",
  );
});

Deno.test("buildGarmentFitDetail walks the whole adjective ladder for chest", () => {
  // chest thresholds: slimMin 4, regularMax 15, looseMax 24.
  const at = (garment: number) =>
    buildGarmentFitDetail(size("M", { chest_circumference: garment }), {
      chest: 100,
    });

  assertStringIncludes(
    at(98)!,
    "compression — the fabric is pulled taut against the body",
  );
  assertStringIncludes(at(102)!, "skin-close, follows the body with no slack");
  assertStringIncludes(at(110)!, "fitted, follows the body with a little room");
  assertStringIncludes(at(120)!, "loose, hangs away from the body");
  assertStringIncludes(at(130)!, "billowy, drapes well clear of the body");
});

Deno.test("buildGarmentFitDetail walks the whole adjective ladder for hips", () => {
  // hips thresholds: slimMin 2, regularMax 9, looseMax 14.
  const at = (garment: number) =>
    buildGarmentFitDetail(size("M", { hip_circumference: garment }), {
      hips: 100,
    });

  assertStringIncludes(
    at(98)!,
    "compression — the fabric is pulled taut against the body",
  );
  assertStringIncludes(at(101)!, "skin-close, follows the body with no slack");
  assertStringIncludes(at(108)!, "fitted, follows the body with a little room");
  assertStringIncludes(at(112)!, "loose, hangs away from the body");
  assertStringIncludes(at(120)!, "billowy, drapes well clear of the body");
});

Deno.test("buildGarmentFitDetail walks the whole adjective ladder for thigh", () => {
  // thigh thresholds: slimMin 1, regularMax 7, looseMax 12.
  const at = (garment: number) =>
    buildGarmentFitDetail(size("M", { thigh_circumference: garment }), {
      thigh: 50,
    });

  assertStringIncludes(
    at(48)!,
    "compression — the fabric is pulled taut against the body",
  );
  assertStringIncludes(
    at(50.5)!,
    "skin-close, follows the body with no slack",
  );
  assertStringIncludes(at(55)!, "fitted, follows the body with a little room");
  assertStringIncludes(at(60)!, "loose, hangs away from the body");
  assertStringIncludes(at(65)!, "billowy, drapes well clear of the body");
});

Deno.test("buildGarmentFitDetail never reports waist as skin-close: its slimMin is 0, so zero ease is already fitted", () => {
  const detail = buildGarmentFitDetail(size("M", { waist_circumference: 90 }), {
    waist: 90,
  });
  assertStringIncludes(detail!, "fitted, follows the body with a little room");
});

Deno.test("buildGarmentFitDetail uses each dimension's own thresholds", () => {
  // +6cm is `fitted` on a chest (regularMax 15) but `loose` on a waist (regularMax 4).
  const chest = buildGarmentFitDetail(size("M", { chest_circumference: 96 }), {
    chest: 90,
  });
  const waist = buildGarmentFitDetail(size("M", { waist_circumference: 96 }), {
    waist: 90,
  });

  assertStringIncludes(chest!, "fitted, follows the body with a little room");
  assertStringIncludes(waist!, "loose, hangs away from the body");
});

Deno.test("buildGarmentFitDetail reports shoulders as a seam position, not an adjective", () => {
  const detail = buildGarmentFitDetail(size("M", { shoulder_width: 45 }), {
    shoulder: 43,
  });
  assertEquals(
    detail,
    "size M: shoulder seams 45cm on 43cm shoulders, sitting 1cm past each shoulder point",
  );
});

Deno.test("buildGarmentFitDetail reports matched shoulders as sitting exactly on the shoulder points", () => {
  const detail = buildGarmentFitDetail(size("M", { shoulder_width: 43 }), {
    shoulder: 43,
  });
  assertStringIncludes(detail!, "sitting exactly on the shoulder points");
});

Deno.test("buildGarmentFitDetail reports narrow shoulders as sitting inside the shoulder point", () => {
  const detail = buildGarmentFitDetail(size("M", { shoulder_width: 41 }), {
    shoulder: 43,
  });
  assertStringIncludes(detail!, "sitting 1cm inside each shoulder point");
});

Deno.test("buildGarmentFitDetail pairs length with the wearer's height", () => {
  const detail = buildGarmentFitDetail(size("M", { length: 68 }), {
    height: 170,
  });
  assertEquals(detail, "size M: body length 68cm on a 170cm wearer");
});

Deno.test("buildGarmentFitDetail gives length alone when height is unknown", () => {
  const detail = buildGarmentFitDetail(size("M", { length: 68 }), {
    chest: 92,
  });
  assertEquals(detail, "size M: body length 68cm");
});

Deno.test("buildGarmentFitDetail states sleeve length without a body counterpart", () => {
  const detail = buildGarmentFitDetail(size("M", { sleeve_length: 22 }), {
    chest: 92,
  });
  assertEquals(detail, "size M: sleeve length 22cm");
});

Deno.test("buildGarmentFitDetail joins clauses in a fixed order", () => {
  const detail = buildGarmentFitDetail(
    size("M", {
      chest_circumference: 104,
      shoulder_width: 45,
      length: 68,
      sleeve_length: 22,
    }),
    { chest: 92, shoulder: 43, height: 170 },
  );
  assertEquals(
    detail,
    "size M: chest 104cm on a 92cm chest (+12cm — fitted, follows the body with a little room); " +
      "shoulder seams 45cm on 43cm shoulders, sitting 1cm past each shoulder point; " +
      "body length 68cm on a 170cm wearer; sleeve length 22cm",
  );
});

Deno.test("buildGarmentFitDetail skips dimensions missing on either side", () => {
  const detail = buildGarmentFitDetail(
    size("M", { chest_circumference: 104, waist_circumference: 90 }),
    { chest: 92 },
  );
  assertEquals(detail?.includes("waist"), false);
});

Deno.test("buildGarmentFitDetail returns undefined when nothing overlaps", () => {
  assertEquals(
    buildGarmentFitDetail(size("M", { waist_circumference: 90 }), {
      chest: 92,
    }),
    undefined,
  );
});

Deno.test("buildGarmentFitDetail returns undefined when the size has no measurements", () => {
  assertEquals(
    buildGarmentFitDetail(size("M", null), { chest: 92 }),
    undefined,
  );
});

Deno.test("buildGarmentFitDetail places the wearer inside the recommended height range", () => {
  const detail = buildGarmentFitDetail(
    size("M", null, {
      height: { min: 160, max: 170 },
    }),
    { height: 165 },
  );
  assertEquals(
    detail,
    "size M: recommended for wearers 160–170cm tall; this wearer is 165cm, within that range",
  );
});

Deno.test("buildGarmentFitDetail says how far a wearer falls outside a range, in that range's unit", () => {
  const tall = buildGarmentFitDetail(
    size("M", null, {
      height: { min: 160, max: 170 },
    }),
    { height: 174 },
  );
  assertStringIncludes(tall!, "this wearer is 174cm, 4cm above that range");

  const light = buildGarmentFitDetail(
    size("M", null, {
      weight: { min: 50, max: 60 },
    }),
    { weight: 47 },
  );
  assertEquals(
    light,
    "size M: recommended for wearers of 50–60kg; this wearer is 47kg, 3kg below that range",
  );
});

Deno.test("buildGarmentFitDetail appends body measurement ranges after the measurement clauses", () => {
  const detail = buildGarmentFitDetail(
    size("M", { length: 68 }, {
      height: { min: 160, max: 170 },
      weight: { min: 50, max: 60 },
    }),
    { height: 170, weight: 58 },
  );
  assertEquals(
    detail,
    "size M: body length 68cm on a 170cm wearer; " +
      "recommended for wearers 160–170cm tall; this wearer is 170cm, within that range; " +
      "recommended for wearers of 50–60kg; this wearer is 58kg, within that range",
  );
});

Deno.test("buildGarmentFitDetail skips a body measurement range the shopper has no value for", () => {
  assertEquals(
    buildGarmentFitDetail(
      size("M", null, {
        height: { min: 160, max: 170 },
      }),
      { chest: 92 },
    ),
    undefined,
  );
});

Deno.test("buildGarmentFitDetail trims a half-centimetre to one decimal", () => {
  const detail = buildGarmentFitDetail(
    size("M", { chest_circumference: 104.5 }),
    {
      chest: 92,
    },
  );
  assertStringIncludes(detail!, "chest 104.5cm on a 92cm chest (+12.5cm");
});

Deno.test("buildGarmentFitDetail caps an overlong detail at the limit", () => {
  const detail = buildGarmentFitDetail(
    size("x".repeat(LIMITS.MAX_GARMENT_FIT_LENGTH + 200), {
      chest_circumference: 104,
    }),
    { chest: 92 },
  );
  assertEquals(detail?.length, LIMITS.MAX_GARMENT_FIT_LENGTH);
});
