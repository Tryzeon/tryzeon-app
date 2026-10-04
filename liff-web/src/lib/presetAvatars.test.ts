import { describe, expect, it } from "vitest";
import { parseGender, PRESET_AVATARS, presetsForGender } from "./presetAvatars";

describe("presetsForGender", () => {
  it("offers the preset matching the gender picked at onboarding", () => {
    expect(presetsForGender("female").map((p) => p.id)).toEqual(["female"]);
    expect(presetsForGender("male").map((p) => p.id)).toEqual(["male"]);
  });

  it("offers every preset when the gender is unknown", () => {
    expect(presetsForGender(null)).toEqual(PRESET_AVATARS);
  });
});

describe("parseGender", () => {
  it("accepts only the profile's enum values", () => {
    expect(parseGender("female")).toBe("female");
    expect(parseGender("male")).toBe("male");
    expect(parseGender("other")).toBeNull();
    expect(parseGender(null)).toBeNull();
  });
});
