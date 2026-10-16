import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { StoredAvatar } from "../api/avatar-wire";
import {
  type AvatarPreview,
  avatarStatus,
  settleOnSave,
  settleOnSigned,
  shownUrl,
} from "./avatar";

const PRESET: StoredAvatar = { kind: "preset", id: "female" };
const OLD_UPLOAD: StoredAvatar = { kind: "uploaded", path: "u1/avatar/1.jpg" };
const NEW_UPLOAD: StoredAvatar = { kind: "uploaded", path: "u1/avatar/2.jpg" };
const UPLOADING: AvatarPreview = { kind: "upload", objectUrl: "blob:local", savedAs: null };

beforeEach(() => {
  vi.stubEnv("VITE_R2_PUBLIC_IMAGES_BASE_URL", "https://images.test");
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("shownUrl", () => {
  it("shows a preset straight from the CDN, with no signature", () => {
    expect(shownUrl(null, PRESET, null)).toBe("https://images.test/presets/female.jpg");
  });

  it("shows an own photo only once its own path is signed", () => {
    const signedOld = { path: "u1/avatar/1.jpg", url: "https://signed/1" };
    const signedNew = { path: "u1/avatar/2.jpg", url: "https://signed/2" };
    expect(shownUrl(null, NEW_UPLOAD, null)).toBeNull();
    expect(shownUrl(null, NEW_UPLOAD, signedOld)).toBeNull();
    expect(shownUrl(null, NEW_UPLOAD, signedNew)).toBe("https://signed/2");
  });

  it("puts the model being saved in front of the saved one", () => {
    expect(shownUrl(UPLOADING, PRESET, null)).toBe("blob:local");
    expect(
      shownUrl(
        { kind: "preset", id: "male" },
        OLD_UPLOAD,
        { path: "u1/avatar/1.jpg", url: "https://signed/1" },
      ),
    ).toBe("https://images.test/presets/male.jpg");
  });

  it("shows nothing without a model", () => {
    expect(shownUrl(null, null, null)).toBeNull();
  });
});

describe("avatarStatus", () => {
  it("is ready for a preset or no model, which need no signature", () => {
    expect(avatarStatus(PRESET, null)).toBe("ready");
    expect(avatarStatus(null, null)).toBe("ready");
  });

  it("loads until this path is signed", () => {
    expect(avatarStatus(NEW_UPLOAD, null)).toBe("loading");
    expect(avatarStatus(NEW_UPLOAD, { path: "u1/avatar/1.jpg", url: "https://signed/1" }))
      .toBe("loading");
  });

  it("settles on this path's signature", () => {
    expect(avatarStatus(NEW_UPLOAD, { path: "u1/avatar/2.jpg", url: "https://signed/2" }))
      .toBe("ready");
    expect(avatarStatus(NEW_UPLOAD, { path: "u1/avatar/2.jpg", url: null })).toBe("error");
  });
});

describe("settleOnSave", () => {
  it("drops a preset preview at once: the saved preset shows the same image", () => {
    expect(settleOnSave({ kind: "preset", id: "female" }, PRESET)).toBeNull();
  });

  it("keeps an upload preview until the saved path is signed", () => {
    expect(settleOnSave(UPLOADING, NEW_UPLOAD)).toEqual({
      kind: "upload",
      objectUrl: "blob:local",
      savedAs: "u1/avatar/2.jpg",
    });
  });
});

describe("settleOnSigned", () => {
  it("retires the upload preview once its own path is signed", () => {
    expect(settleOnSigned({ ...UPLOADING, savedAs: "u1/avatar/2.jpg" }, "u1/avatar/2.jpg"))
      .toBeNull();
  });

  it("ignores a slower signature for an earlier save", () => {
    const saved: AvatarPreview = { ...UPLOADING, savedAs: "u1/avatar/2.jpg" };
    expect(settleOnSigned(saved, "u1/avatar/1.jpg")).toBe(saved);
    expect(settleOnSigned(UPLOADING, "u1/avatar/1.jpg")).toBe(UPLOADING);
  });

  it("leaves a preset preview to its own save", () => {
    const preset: AvatarPreview = { kind: "preset", id: "male" };
    expect(settleOnSigned(preset, "u1/avatar/1.jpg")).toBe(preset);
  });
});
