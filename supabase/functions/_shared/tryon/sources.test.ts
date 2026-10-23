import { assertEquals } from "@std/assert";
import { loadGarments, makeSourceLoader } from "./sources.ts";
import {
  USER_AVATARS_BUCKET,
  WARDROBE_IMAGES_BUCKET,
} from "../supabase-storage.ts";
import type { SourceLoader } from "./sources.ts";

function fakeClient() {
  const downloads: string[] = [];
  const client = {
    storage: {
      from(bucket: string) {
        return {
          download(path: string) {
            downloads.push(`${bucket}/${path}`);
            return Promise.resolve({
              data: {
                arrayBuffer: () => Promise.resolve(new Uint8Array([65]).buffer),
              },
              error: null,
            });
          },
        };
      },
    },
  };
  // deno-lint-ignore no-explicit-any
  return { client: client as any, downloads };
}

function fakePublicImages() {
  const keys: string[] = [];
  const download = (key: string) => {
    keys.push(key);
    return Promise.resolve("UFVCTElD");
  };
  return { download, keys };
}

Deno.test("makeSourceLoader passes base64 through without touching any store", async () => {
  const { client, downloads } = fakeClient();
  const publicImages = fakePublicImages();
  const load = makeSourceLoader(client, publicImages.download);
  assertEquals(await load({ base64: "ALREADY" }), "ALREADY");
  assertEquals(downloads, []);
  assertEquals(publicImages.keys, []);
});

Deno.test("makeSourceLoader downloads a storage object from the bucket it names", async () => {
  const { client, downloads } = fakeClient();
  const publicImages = fakePublicImages();
  const load = makeSourceLoader(client, publicImages.download);
  assertEquals(
    await load({ bucket: USER_AVATARS_BUCKET, path: "u1/avatar.jpg" }),
    "QQ==",
  );
  assertEquals(
    await load({ bucket: WARDROBE_IMAGES_BUCKET, path: "u1/top/a.jpg" }),
    "QQ==",
  );
  assertEquals(downloads, [
    `${USER_AVATARS_BUCKET}/u1/avatar.jpg`,
    `${WARDROBE_IMAGES_BUCKET}/u1/top/a.jpg`,
  ]);
  assertEquals(publicImages.keys, []);
});

Deno.test("makeSourceLoader fetches a public image key from the public images store", async () => {
  const { client, downloads } = fakeClient();
  const publicImages = fakePublicImages();
  const load = makeSourceLoader(client, publicImages.download);
  assertEquals(
    await load({ publicImageKey: "presets/female.jpg" }),
    "UFVCTElD",
  );
  assertEquals(publicImages.keys, ["presets/female.jpg"]);
  assertEquals(downloads, []);
});

Deno.test("loadGarments preserves garment grouping and image order", async () => {
  const load: SourceLoader = (source) =>
    Promise.resolve(
      "base64" in source
        ? source.base64
        : "publicImageKey" in source
        ? `@${source.publicImageKey}`
        : `@${source.bucket}/${source.path}`,
    );
  const groups = await loadGarments(
    [
      { images: [{ base64: "A1" }, { publicImageKey: "stores/a2.jpg" }] },
      { images: [{ bucket: WARDROBE_IMAGES_BUCKET, path: "u1/b1.jpg" }] },
    ],
    load,
  );
  assertEquals(groups, [["A1", "@stores/a2.jpg"], [
    `@${WARDROBE_IMAGES_BUCKET}/u1/b1.jpg`,
  ]]);
});
