import { describe, expect, it } from "vitest";
import { publicImageUrl } from "./publicImage";

describe("publicImageUrl", () => {
  it("joins base and key with exactly one slash", () => {
    expect(publicImageUrl("https://img.test", "a/1.jpg")).toBe(
      "https://img.test/a/1.jpg",
    );
    expect(publicImageUrl("https://img.test///", "a/1.jpg")).toBe(
      "https://img.test/a/1.jpg",
    );
  });
});
