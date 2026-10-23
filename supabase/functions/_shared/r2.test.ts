import { assertStringIncludes } from "@std/assert";
import { generatePresignedPutUrl } from "./r2.ts";

Deno.test("generatePresignedPutUrl signs a path-style URL", async () => {
  Deno.env.set("R2_ACCESS_KEY_ID", "test-key");
  Deno.env.set("R2_SECRET_ACCESS_KEY", "test-secret");
  Deno.env.set("R2_ENDPOINT", "https://account.r2.example.com");
  Deno.env.set("R2_TRYON_VIDEOS_BUCKET_NAME", "videos");
  Deno.env.set("R2_TRYON_IMAGES_BUCKET_NAME", "images");
  Deno.env.set("R2_PUBLIC_IMAGES_BUCKET_NAME", "public-images");

  const url = await generatePresignedPutUrl({
    key: "stores/a.png",
    contentType: "image/png",
    contentLength: 1,
  });

  assertStringIncludes(
    url,
    "https://account.r2.example.com/public-images/stores/a.png?",
  );
});
