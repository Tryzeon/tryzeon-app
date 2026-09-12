import { assertEquals } from "@std/assert";
import { ANALYSIS_PROMPT, ANALYSIS_SCHEMA, toResponse } from "./analysis.ts";
import { GARMENT_TYPE_VALUES } from "../_shared/vocabularies.ts";

type PropertySpec = { type: string; enum?: string[] };

const schemaProperties = (): Record<string, PropertySpec> =>
  (ANALYSIS_SCHEMA as { properties: Record<string, PropertySpec> }).properties;

Deno.test("toResponse passes each valid garment type through", () => {
  for (const type of ["top", "pants", "skirt", "dress", "outerwear", "others"]) {
    assertEquals(toResponse({ garment_type: type, tags: [] }).garment_type, type);
  }
});

Deno.test("toResponse maps the unknown sentinel to null", () => {
  assertEquals(toResponse({ garment_type: "unknown", tags: [] }).garment_type, null);
});

Deno.test("toResponse nulls a garment type outside the list, including the retired values", () => {
  for (const retired of ["shoes", "bottoms", "sets"]) {
    assertEquals(toResponse({ garment_type: retired, tags: [] }).garment_type, null);
  }
});

Deno.test("toResponse nulls a non-string or missing garment type", () => {
  assertEquals(toResponse({ garment_type: 3, tags: [] }).garment_type, null);
  assertEquals(toResponse({ tags: [] }).garment_type, null);
});

Deno.test("toResponse ignores the retired category field", () => {
  assertEquals(toResponse({ category: "top", tags: [] }).garment_type, null);
});

Deno.test("toResponse drops tags that are not non-empty strings", () => {
  assertEquals(
    toResponse({ garment_type: "top", tags: ["藍", "", 7, null, "棉"] }).tags,
    ["藍", "棉"],
  );
});

Deno.test("toResponse caps tags at the stated maximum", () => {
  const overLong = ["黑", "白", "灰", "米", "棕", "紅", "橙", "黃"];
  assertEquals(toResponse({ garment_type: "top", tags: overLong }).tags, [
    "黑",
    "白",
    "灰",
    "米",
    "棕",
    "紅",
  ]);
});

Deno.test("toResponse treats a non-array tags field as empty", () => {
  assertEquals(toResponse({ garment_type: "top", tags: "藍" }).tags, []);
  assertEquals(toResponse({ garment_type: "top" }).tags, []);
});

Deno.test("toResponse passes a fully valid answer through", () => {
  assertEquals(toResponse({ garment_type: "outerwear", tags: ["黑", "皮革"] }), {
    garment_type: "outerwear",
    tags: ["黑", "皮革"],
  });
});

Deno.test("toResponse keeps duplicate tags — the app does not expect them collapsed", () => {
  assertEquals(toResponse({ garment_type: "top", tags: ["黑", "黑"] }).tags, ["黑", "黑"]);
});

// Locked so a future pass at parity with the sibling module doesn't add
// `.trim()` unnoticed.
Deno.test("toResponse does not trim tags", () => {
  assertEquals(toResponse({ garment_type: "top", tags: [" 黑 "] }).tags, [" 黑 "]);
});

// The three below lock the prompt, the schema and the sanitiser to one
// vocabulary: change one and these fail rather than the model quietly answering
// with a word nothing accepts.
Deno.test("ANALYSIS_PROMPT offers every garment type the schema accepts", () => {
  for (const value of schemaProperties().garment_type.enum ?? []) {
    assertEquals(
      ANALYSIS_PROMPT.includes(value),
      true,
      `prompt never offers garment_type=${value}`,
    );
  }
});

Deno.test("ANALYSIS_SCHEMA accepts exactly the database's garment types plus the sentinel", () => {
  assertEquals(schemaProperties().garment_type.enum, [...GARMENT_TYPE_VALUES, "unknown"]);
});

Deno.test("ANALYSIS_PROMPT teaches the one garment type the sanitiser rejects", () => {
  const accepted = schemaProperties().garment_type.enum ?? [];
  const sentinels = accepted.filter(
    (v) => toResponse({ garment_type: v, tags: [] }).garment_type === null,
  );
  assertEquals(
    sentinels.length,
    1,
    "expected exactly one value the schema offers and the sanitiser strips",
  );
  assertEquals(ANALYSIS_PROMPT.includes(sentinels[0]), true);
});

Deno.test("ANALYSIS_PROMPT states the tag cap the sanitiser enforces", () => {
  const many = Array.from({ length: 20 }, (_, i) => `t${i}`);
  const cap = toResponse({ garment_type: "top", tags: many }).tags.length;
  assertEquals(
    ANALYSIS_PROMPT.includes(`最多 ${cap} 個`),
    true,
    `prompt does not state the ${cap}-tag cap the sanitiser enforces`,
  );
});

Deno.test("ANALYSIS_SCHEMA requires every field it declares", () => {
  const required = (ANALYSIS_SCHEMA as { required: string[] }).required;
  assertEquals([...required].sort(), Object.keys(schemaProperties()).sort());
});
