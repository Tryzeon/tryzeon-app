import { describe, expect, it } from "vitest";
import { paneOf } from "./pane";

describe("paneOf", () => {
  it("routes each tab's path to its pane", () => {
    expect(paneOf("/home")).toBe("home");
    expect(paneOf("/chat")).toBe("chat");
    expect(paneOf("/product/p1")).toBe("product");
    expect(paneOf("/")).toBe("shop");
    expect(paneOf("/store/s1")).toBe("shop");
  });

  it("accepts a trailing slash", () => {
    expect(paneOf("/chat/")).toBe("chat");
    expect(paneOf("/home/")).toBe("home");
  });
});
