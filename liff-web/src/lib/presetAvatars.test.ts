import { afterEach, describe, expect, it, vi } from "vitest";
import {
  parseGender,
  PRESET_AVATARS,
  presetAvatarUrl,
  presetsForGender,
} from "./presetAvatars";

describe("PRESET_AVATARS", () => {
  it("names each preset by its own id, apart from the gender it is for", () => {
    expect(PRESET_AVATARS).toEqual([
      { id: "female", gender: "female", label: "女性模特" },
      { id: "male", gender: "male", label: "男性模特" },
    ]);
  });
});

describe("presetsForGender", () => {
  it("offers the presets made for the gender picked at onboarding", () => {
    expect(presetsForGender("female").map((p) => p.id)).toEqual(["female"]);
    expect(presetsForGender("female").every((p) => p.gender === "female")).toBe(true);
    expect(presetsForGender("male").map((p) => p.id)).toEqual(["male"]);
    expect(presetsForGender("male").every((p) => p.gender === "male")).toBe(true);
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

describe("presetAvatarUrl", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("points at the preset's object on the public images CDN", () => {
    vi.stubEnv("VITE_R2_PUBLIC_IMAGES_BASE_URL", "https://images.test/");
    expect(presetAvatarUrl("female")).toBe("https://images.test/presets/female.jpg");
    expect(presetAvatarUrl("male")).toBe("https://images.test/presets/male.jpg");
  });
});
