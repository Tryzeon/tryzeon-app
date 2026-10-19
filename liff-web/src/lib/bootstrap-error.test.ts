import { describe, expect, it } from "vitest";
import { BootstrapError, describeError } from "./bootstrap-error";

describe("describeError", () => {
  it("keeps the name and status of an HTTP error", () => {
    const err = Object.assign(new Error("request failed"), { name: "ApiError", status: 401 });
    expect(describeError(err)).toBe("ApiError 401: request failed");
  });

  it("reads a plain error object such as PostgrestError", () => {
    expect(describeError({ code: "42501", message: "permission denied" }))
      .toBe("42501: permission denied");
  });

  it("stringifies a non-object", () => {
    expect(describeError("boom")).toBe("boom");
  });
});

describe("BootstrapError", () => {
  it("prefixes the failing step", () => {
    const err = new BootstrapError("session", new TypeError("Failed to fetch"));
    expect(err.message).toBe("session: TypeError: Failed to fetch");
  });
});
