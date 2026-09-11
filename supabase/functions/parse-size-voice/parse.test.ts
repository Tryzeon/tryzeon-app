import { assertEquals } from "@std/assert";
import { normalizeParsedSizes, normalizeSizeName } from "./parse.ts";

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

Deno.test("normalizeParsedSizes keeps thigh_circumference", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "L",
        garment_measurements: {
          thigh_circumference: { value: 60, unit: "centimeter" },
        },
      },
    ],
  });
  assertEquals(parsed[0].garment_measurements.thigh_circumference, {
    value: 60,
    unit: "centimeter",
  });
});

Deno.test("normalizeParsedSizes normalizes the name it returns", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "XXL",
        garment_measurements: {
          chest_circumference: { value: 100, unit: "centimeter" },
        },
      },
      { name: "US 10", garment_measurements: {} },
    ],
  });
  assertEquals(parsed.map((s) => s.name), ["2XL", "US 10"]);
  assertEquals(parsed[0].garment_measurements.chest_circumference, {
    value: 100,
    unit: "centimeter",
  });
});

Deno.test("normalizeParsedSizes keeps a body measurement range whose bounds are ordered and plausible", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "M",
        garment_measurements: {},
        body_measurement_ranges: {
          height: { min: 160, max: 170 },
          weight: { min: 50, max: 60 },
        },
      },
    ],
  });
  assertEquals(parsed[0].body_measurement_ranges, {
    height: { min: 160, max: 170 },
    weight: { min: 50, max: 60 },
  });
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
    sizes: [{ name: "M", garment_measurements: {}, body_measurement_ranges: ranges }],
  });
  assertEquals(parsed[0].body_measurement_ranges, ranges);
});

Deno.test("normalizeParsedSizes drops a circumference range above the app's body measurement maximum", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "M",
        garment_measurements: {},
        body_measurement_ranges: { chest: { min: 88, max: 201 } },
      },
    ],
  });
  assertEquals(parsed[0].body_measurement_ranges, {});
});

Deno.test("normalizeParsedSizes drops a body measurement range that is reversed, non-positive or implausibly large", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "M",
        garment_measurements: {},
        body_measurement_ranges: {
          height: { min: 170, max: 160 },
          weight: { min: 0, max: 60 },
        },
      },
      {
        name: "L",
        garment_measurements: {},
        body_measurement_ranges: { height: { min: 160, max: 1700 } },
      },
      { name: "XL", garment_measurements: {} },
    ],
  });
  assertEquals(parsed.map((s) => s.body_measurement_ranges), [{}, {}, {}]);
});

Deno.test("normalizeParsedSizes accepts a single-point body measurement range", () => {
  const parsed = normalizeParsedSizes({
    sizes: [{
      name: "M",
      garment_measurements: {},
      body_measurement_ranges: { height: { min: 165, max: 165 } },
    }],
  });
  assertEquals(parsed[0].body_measurement_ranges.height, { min: 165, max: 165 });
});
