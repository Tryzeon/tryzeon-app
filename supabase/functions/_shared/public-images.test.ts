import { assertEquals } from "@std/assert";
import { publicImageUrl } from "./public-images.ts";

Deno.test("publicImageUrl joins the CDN base and the object key", () => {
  assertEquals(
    publicImageUrl("https://images.example.com", "stores/s1/logo.png"),
    "https://images.example.com/stores/s1/logo.png",
  );
});

Deno.test("publicImageUrl tolerates trailing slashes on the base", () => {
  assertEquals(
    publicImageUrl("https://images.example.com//", "presets/female.jpg"),
    "https://images.example.com/presets/female.jpg",
  );
});
