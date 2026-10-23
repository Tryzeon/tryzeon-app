import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  buildPrompt,
  buildSchema,
  normalizeParsedSizes,
  normalizeSizeName,
  validateRequest,
} from "./parse.ts";

Deno.test("normalizeSizeName maps aliases onto the canonical literal", () => {
  assertEquals(normalizeSizeName("XXL"), "2XL");
  assertEquals(normalizeSizeName("xxl"), "2XL");
  assertEquals(normalizeSizeName("均碼"), "均碼");
  assertEquals(normalizeSizeName("one size"), "均碼");
  assertEquals(normalizeSizeName("Medium"), "M");
  assertEquals(normalizeSizeName("1XL"), "XL");
});

Deno.test("normalizeSizeName trims and upper-cases a standard label", () => {
  assertEquals(normalizeSizeName(" m "), "M");
  assertEquals(normalizeSizeName("2xl"), "2XL");
});

Deno.test("normalizeSizeName keeps an unrecognised name as spoken", () => {
  assertEquals(normalizeSizeName("US 10"), "US 10");
  assertEquals(normalizeSizeName("4XL"), "4XL");
  assertEquals(normalizeSizeName(" 加大 "), "加大");
  assertEquals(normalizeSizeName(""), "");
});

Deno.test("normalizeParsedSizes keys each garment measurement by its type", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [
        { type: "shoulder_width", value: 40, unit: "centimeter" },
        { type: "chest_circumference", value: 96, unit: "centimeter" },
        { type: "length", value: 65, unit: "centimeter" },
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed, [{
    name: "M",
    garment_measurements: {
      shoulder_width: { value: 40, unit: "centimeter" },
      chest_circumference: { value: 96, unit: "centimeter" },
      length: { value: 65, unit: "centimeter" },
    },
    body_measurement_ranges: {},
  }]);
});

Deno.test("normalizeParsedSizes keeps thigh_circumference and leg_opening", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "L",
      garment_measurements: [
        { type: "thigh_circumference", value: 60, unit: "centimeter" },
        { type: "leg_opening", value: 18, unit: "centimeter" },
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed[0].garment_measurements, {
    thigh_circumference: { value: 60, unit: "centimeter" },
    leg_opening: { value: 18, unit: "centimeter" },
  });
});

Deno.test("normalizeParsedSizes drops an entry outside the garment vocabulary or its units", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [
        { type: "inseam", value: 72, unit: "centimeter" },
        { type: "length", value: 72, unit: "foot" },
        { type: "waist_circumference", value: "70", unit: "centimeter" },
        null,
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed[0].garment_measurements, {});
});

Deno.test("normalizeParsedSizes keeps the last value of a measurement spoken twice", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [
        { type: "waist_circumference", value: 70, unit: "centimeter" },
        { type: "waist_circumference", value: 68, unit: "centimeter" },
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed[0].garment_measurements, {
    waist_circumference: { value: 68, unit: "centimeter" },
  });
});

// Plausibility is the size form's call, so a misheard number reaches the store
// owner as a flagged cell rather than vanishing here.
Deno.test("normalizeParsedSizes passes an implausible garment value through", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [
        { type: "waist_circumference", value: 2800, unit: "centimeter" },
        { type: "chest_circumference", value: 0, unit: "centimeter" },
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed[0].garment_measurements, {
    waist_circumference: { value: 2800, unit: "centimeter" },
    chest_circumference: { value: 0, unit: "centimeter" },
  });
});

Deno.test("normalizeParsedSizes normalizes the name it returns", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      { name: "XXL", garment_measurements: [], body_measurement_ranges: [] },
      { name: "US 10", garment_measurements: [], body_measurement_ranges: [] },
    ],
  });
  assertEquals(parsed.map((s) => s.name), ["2XL", "US 10"]);
});

Deno.test("normalizeParsedSizes keeps a body measurement range for every body dimension", () => {
  const ranges = {
    height: { min: 160, max: 170 },
    weight: { min: 50, max: 60 },
    shoulder: { min: 40, max: 44 },
    chest: { min: 88, max: 96 },
    waist: { min: 70, max: 78 },
    hips: { min: 90, max: 98 },
    thigh: { min: 50, max: 56 },
  };
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [],
      body_measurement_ranges: Object.entries(ranges).map(([type, r]) => ({
        type,
        ...r,
      })),
    }],
  });
  assertEquals(parsed[0].body_measurement_ranges, ranges);
});

Deno.test("normalizeParsedSizes accepts a single-point body measurement range", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [],
      body_measurement_ranges: [{ type: "height", min: 165, max: 165 }],
    }],
  });
  assertEquals(parsed[0].body_measurement_ranges.height, {
    min: 165,
    max: 165,
  });
});

Deno.test("normalizeParsedSizes passes an implausible body range through and drops an unknown type", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [],
      body_measurement_ranges: [
        { type: "height", min: 170, max: 1600 },
        { type: "arm", min: 20, max: 30 },
        { type: "weight", min: "50", max: 60 },
      ],
    }],
  });
  assertEquals(parsed[0].body_measurement_ranges, {
    height: { min: 170, max: 1600 },
  });
});

Deno.test("normalizeParsedSizes treats missing arrays as empty", () => {
  assertEquals(normalizeParsedSizes({ sizes: [{ name: "M" }] }), [{
    name: "M",
    garment_measurements: {},
    body_measurement_ranges: {},
  }]);
  assertEquals(normalizeParsedSizes({}), []);
});

Deno.test("normalizeParsedSizes passes a unit the model could not settle through", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: [
        { type: "waist_circumference", value: 28, unit: "cun_ambiguous" },
        { type: "chest_circumference", value: 50, unit: "unspecified" },
      ],
      body_measurement_ranges: [],
    }],
  });
  assertEquals(parsed[0].garment_measurements, {
    waist_circumference: { value: 28, unit: "cun_ambiguous" },
    chest_circumference: { value: 50, unit: "unspecified" },
  });
});

const AUDIO = "A".repeat(32);

Deno.test("validateRequest needs only the audio and its mime type", () => {
  const result = validateRequest({ audioBase64: AUDIO, mimeType: "audio/mp4" });
  assertEquals(result, { ok: true, base64: AUDIO, mimeType: "audio/mp4" });
});

Deno.test("validateRequest rejects an unsupported mime type", async () => {
  const result = validateRequest({ audioBase64: AUDIO, mimeType: "audio/ogg" });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.response.status, 400);
    assertEquals((await result.response.json()).code, "BAD_REQUEST");
  }
});

Deno.test("buildPrompt names every unit the model may answer with", () => {
  const prompt = buildPrompt();
  assertStringIncludes(prompt, "cun_ambiguous");
  assertStringIncludes(prompt, "unspecified");
});

Deno.test("buildPrompt asks for no arithmetic and no default unit", () => {
  const prompt = buildPrompt();
  assertEquals(prompt.includes("乘以"), false);
  assertEquals(prompt.includes("沒提單位時填"), false);
  assertEquals(prompt.includes("currentUnit"), false);
});

Deno.test("buildSchema offers the model the unsettled units", () => {
  const schema = buildSchema() as SchemaNode;
  const unit = schema.properties!.sizes.items!.properties!.garment_measurements
    .items!.properties!.unit;
  assertEquals(unit.enum, [
    "centimeter",
    "cun",
    "inch",
    "cun_ambiguous",
    "unspecified",
  ]);
});

type SchemaNode = {
  type?: string;
  enum?: string[];
  properties?: Record<string, SchemaNode>;
  items?: SchemaNode;
  required?: string[];
};

// Vertex writes an object's optional keys in a fixed order, which cost spoken
// measurements their values; every object in this schema must require all its
// keys.
Deno.test("buildSchema leaves no object key optional", () => {
  const visit = (node: SchemaNode, path: string) => {
    if (node.properties) {
      assertEquals(
        [...(node.required ?? [])].sort(),
        Object.keys(node.properties).sort(),
        `${path} has an optional key`,
      );
      for (const [key, child] of Object.entries(node.properties)) {
        visit(child, `${path}.${key}`);
      }
    }
    if (node.items) visit(node.items, `${path}[]`);
  };
  visit(buildSchema() as SchemaNode, "$");
});
