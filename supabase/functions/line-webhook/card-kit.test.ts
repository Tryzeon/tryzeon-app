import { assertEquals } from "@std/assert";
import { CARD_COLOR, overlayHero, primaryButton, secondaryButton } from "./card-kit.ts";

const action = { type: "postback", label: "試穿這件", data: "a=tryon&pid=p1" };

Deno.test("the palette is the design system's, not an approximation", () => {
  assertEquals(CARD_COLOR, {
    primary: "#1A1A1A",
    onPrimary: "#FFFFFF",
    muted: "#9E9E9E",
    outline: "#E5E5E5",
    surface: "#FFFFFF",
    surfaceVariant: "#F7F7F7",
    onImage: "#FFFFFF",
    onImageMuted: "#FFFFFFCC",
    scrim: "#000000B8",
    scrimClear: "#00000000",
  });
});

Deno.test("a button's action is on the box, so the whole button is tappable", () => {
  for (
    const button of [
      primaryButton("試穿這件", action),
      secondaryButton("前往購買", action),
    ]
  ) {
    // deno-lint-ignore no-explicit-any
    const b = button as any;
    assertEquals(b.type, "box");
    assertEquals(b.action, action);
    assertEquals(b.contents[0].action, undefined);
  }
});

Deno.test("the primary button is filled charcoal with white type", () => {
  // deno-lint-ignore no-explicit-any
  const b = primaryButton("試穿這件", action) as any;
  assertEquals(b.backgroundColor, CARD_COLOR.primary);
  assertEquals(b.cornerRadius, "8px");
  assertEquals(b.borderWidth, undefined);
  assertEquals(b.contents[0].text, "試穿這件");
  assertEquals(b.contents[0].color, CARD_COLOR.onPrimary);
  assertEquals(b.contents[0].align, "center");
});

Deno.test("the secondary button is outlined, with no fill", () => {
  // deno-lint-ignore no-explicit-any
  const b = secondaryButton("前往購買", action) as any;
  assertEquals(b.backgroundColor, undefined);
  assertEquals(b.borderWidth, "1px");
  assertEquals(b.borderColor, CARD_COLOR.outline);
  assertEquals(b.cornerRadius, "8px");
  assertEquals(b.contents[0].color, CARD_COLOR.primary);
});

const image = { type: "image", url: "https://img.example/p.jpg", size: "full", aspectRatio: "1:1", aspectMode: "cover" };
const overlay = [{ type: "text", text: "白襯衫" }];

Deno.test("an overlay hero keeps the photo first and lays the text over its bottom edge", () => {
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ image, overlay }) as any;

  // Flex refuses an absolutely positioned first child, so the photo must lead.
  assertEquals(hero.contents[0], image);
  assertEquals(hero.paddingAll, "0px");
  assertEquals(hero.contents[1].position, "absolute");
  assertEquals(hero.contents[1].offsetBottom, "0px");
  assertEquals(hero.contents[1].offsetStart, "0px");
  assertEquals(hero.contents[1].offsetEnd, "0px");
  assertEquals(hero.contents[1].contents, overlay);
});

Deno.test("the scrim darkens from the bottom up", () => {
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ image, overlay }) as any;

  // 0deg runs bottom to top, so startColor is the bottom edge.
  assertEquals(hero.contents[1].background, {
    type: "linearGradient",
    angle: "0deg",
    startColor: CARD_COLOR.scrim,
    endColor: CARD_COLOR.scrimClear,
  });
});

Deno.test("an overlay hero is tappable only when given an action", () => {
  const tap = { type: "uri", label: "商品詳情", uri: "https://liff.example/product/p1" };
  // deno-lint-ignore no-explicit-any
  assertEquals((overlayHero({ image, overlay, action: tap }) as any).action, tap);
  assertEquals("action" in overlayHero({ image, overlay }), false);
});
