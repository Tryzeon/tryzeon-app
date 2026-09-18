import { describe, expect, it } from "vitest";
import { nearestPage } from "./pager";

describe("nearestPage", () => {
  it("rounds to the page whose midpoint has been crossed", () => {
    expect(nearestPage(0, 390, 3)).toBe(0);
    expect(nearestPage(194, 390, 3)).toBe(0);
    expect(nearestPage(196, 390, 3)).toBe(1);
    expect(nearestPage(780, 390, 3)).toBe(2);
  });

  it("clamps rubber-band overshoot at either edge to a real page", () => {
    expect(nearestPage(-300, 390, 3)).toBe(0);
    expect(nearestPage(1100, 390, 3)).toBe(2);
  });

  it("never goes negative when the track has no pages", () => {
    expect(nearestPage(0, 390, 0)).toBe(0);
  });
});
