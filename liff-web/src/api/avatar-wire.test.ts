import { describe, expect, it } from "vitest";
import {
  avatarColumns,
  avatarUploadPath,
  type AvatarStore,
  commitAvatar,
  parseStoredAvatar,
  supersededUpload,
  type StoredAvatar,
} from "./avatar-wire";

const PRESET: StoredAvatar = { kind: "preset", id: "female" };
const OLD_UPLOAD: StoredAvatar = { kind: "uploaded", path: "u1/avatar/1.jpg" };
const NEW_UPLOAD: StoredAvatar = { kind: "uploaded", path: "u1/avatar/2.jpg" };

describe("parseStoredAvatar", () => {
  it("reads a preset reference", () => {
    expect(parseStoredAvatar({ avatar_path: null, avatar_preset: "male" })).toEqual({
      kind: "preset",
      id: "male",
    });
  });

  it("reads an uploaded photo", () => {
    expect(parseStoredAvatar({ avatar_path: "u1/avatar/1.jpg", avatar_preset: null }))
      .toEqual(OLD_UPLOAD);
  });

  it("reads no model when neither column holds one", () => {
    expect(parseStoredAvatar({ avatar_path: null, avatar_preset: null })).toBeNull();
    expect(parseStoredAvatar({ avatar_path: "", avatar_preset: null })).toBeNull();
  });

  it("reads a preset this client does not know as no model", () => {
    expect(parseStoredAvatar({ avatar_path: null, avatar_preset: "female_2" })).toBeNull();
  });
});

describe("avatarColumns", () => {
  it("writes both columns, so the other source is cleared", () => {
    expect(avatarColumns(PRESET)).toEqual({ avatar_path: null, avatar_preset: "female" });
    expect(avatarColumns(OLD_UPLOAD)).toEqual({
      avatar_path: "u1/avatar/1.jpg",
      avatar_preset: null,
    });
  });
});

describe("supersededUpload", () => {
  it("deletes the previous upload once a preset replaces it", () => {
    expect(supersededUpload(OLD_UPLOAD, PRESET)).toBe("u1/avatar/1.jpg");
  });

  it("deletes the previous upload once a new upload replaces it", () => {
    expect(supersededUpload(OLD_UPLOAD, NEW_UPLOAD)).toBe("u1/avatar/1.jpg");
  });

  it("has nothing to delete when the previous model was a preset or none", () => {
    expect(supersededUpload(PRESET, NEW_UPLOAD)).toBeNull();
    expect(supersededUpload(null, PRESET)).toBeNull();
  });

  it("never deletes the photo that is now in use", () => {
    expect(supersededUpload(OLD_UPLOAD, OLD_UPLOAD)).toBeNull();
  });
});

describe("avatarUploadPath", () => {
  it("files the photo under the user's own folder", () => {
    expect(avatarUploadPath("u1", 1700000000000)).toBe("u1/avatar/1700000000000.jpg");
  });
});

describe("commitAvatar", () => {
  function fakeStore(
    stored: StoredAvatar | null,
    failing: { read?: boolean; write?: boolean } = {},
  ): { store: AvatarStore; calls: string[] } {
    const calls: string[] = [];
    const store: AvatarStore = {
      async read() {
        calls.push("read");
        if (failing.read) throw new Error("read failed");
        return stored;
      },
      async write(avatar) {
        calls.push(`write ${JSON.stringify(avatarColumns(avatar))}`);
        if (failing.write) throw new Error("write failed");
      },
      async discard(path) {
        calls.push(`discard ${path}`);
      },
    };
    return { store, calls };
  }

  it("deletes the photo stored right before the write, not one seen earlier", async () => {
    const changedInApp: StoredAvatar = { kind: "uploaded", path: "u1/avatar/app.jpg" };
    const { store, calls } = fakeStore(changedInApp);

    await commitAvatar(store, PRESET);

    expect(calls).toEqual([
      "read",
      `write ${JSON.stringify(avatarColumns(PRESET))}`,
      "discard u1/avatar/app.jpg",
    ]);
  });

  it("deletes nothing when the stored model was a preset or none", async () => {
    for (const stored of [PRESET, null]) {
      const { store, calls } = fakeStore(stored);
      await commitAvatar(store, NEW_UPLOAD);
      expect(calls.filter((call) => call.startsWith("discard"))).toEqual([]);
    }
  });

  it("keeps the replaced photo when the write fails, discarding only the new upload", async () => {
    const { store, calls } = fakeStore(OLD_UPLOAD, { write: true });

    await expect(commitAvatar(store, NEW_UPLOAD)).rejects.toThrow("write failed");

    expect(calls.filter((call) => call.startsWith("discard"))).toEqual([
      "discard u1/avatar/2.jpg",
    ]);
  });

  it("writes nothing when the stored model cannot be read", async () => {
    const { store, calls } = fakeStore(OLD_UPLOAD, { read: true });

    await expect(commitAvatar(store, NEW_UPLOAD)).rejects.toThrow("read failed");

    expect(calls).toEqual(["read", "discard u1/avatar/2.jpg"]);
  });

  it("deletes nothing when a preset fails to save", async () => {
    const { store, calls } = fakeStore(OLD_UPLOAD, { write: true });

    await expect(commitAvatar(store, PRESET)).rejects.toThrow("write failed");

    expect(calls.filter((call) => call.startsWith("discard"))).toEqual([]);
  });
});
