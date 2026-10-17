import { describe, expect, it } from "vitest";
import { priceText } from "./price";

describe("priceText", () => {
  it("prefixes NT$, groups thousands and drops cents", () => {
    expect(priceText(1280)).toBe("NT$1,280");
    expect(priceText(1199.6)).toBe("NT$1,200");
    expect(priceText(0)).toBe("NT$0");
  });
});
