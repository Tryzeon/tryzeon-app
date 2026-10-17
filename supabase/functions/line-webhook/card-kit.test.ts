import { assertEquals } from "@std/assert";
import {
  CARD_COLOR,
  clampTagLabel,
  cornerTag,
  overlayHero,
  primaryButton,
  sourceLine,
  tryonChip,
} from "./card-kit.ts";

const action = { type: "postback", label: "試穿", data: "a=tryon_product&pid=p1" };

Deno.test("the palette is the design system's, plus translucent steps for controls and type on a photo", () => {
  assertEquals(CARD_COLOR, {
    primary: "#1A1A1A",
    onPrimary: "#FFFFFF",
    muted: "#9E9E9E",
    mutedText: "#6B6B6B",
    outline: "#E5E5E5",
    surface: "#FFFFFF",
    surfaceVariant: "#F7F7F7",
    glass: "#1A1A1AB3",
    glassStroke: "#FFFFFF59",
    onImage: "#FFFFFF",
    scrimStrong: "#000000D6",
    scrimMid: "#0000008C",
    scrimClear: "#00000000",
  });
});

Deno.test("a button's action is on the box, so the whole button is tappable", () => {
  for (const button of [primaryButton("前往購買", action), tryonChip(action)]) {
    // deno-lint-ignore no-explicit-any
    const b = button as any;
    assertEquals(b.type, "box");
    assertEquals(b.action, action);
    assertEquals(b.contents[0].action, undefined);
  }
});

Deno.test("the primary button is filled charcoal with white type", () => {
  // deno-lint-ignore no-explicit-any
  const b = primaryButton("前往購買", action) as any;
  assertEquals(b.backgroundColor, CARD_COLOR.primary);
  assertEquals(b.cornerRadius, "8px");
  assertEquals(b.contents[0].color, CARD_COLOR.onPrimary);
});

Deno.test("the try-on chip is a frosted ink capsule pinned to the bottom-right corner inside a larger tap frame", () => {
  // deno-lint-ignore no-explicit-any
  const frame = tryonChip(action) as any;
  const chip = frame.contents[0];

  assertEquals(frame.position, "absolute");
  assertEquals(frame.offsetBottom, "0px");
  assertEquals(frame.offsetEnd, "0px");
  assertEquals(frame.paddingAll, "8px");
  assertEquals(frame.backgroundColor, undefined);
  assertEquals(chip.backgroundColor, CARD_COLOR.glass);
  assertEquals(chip.borderColor, CARD_COLOR.glassStroke);
  assertEquals(chip.cornerRadius, "100px");
  assertEquals(chip.contents[0], {
    type: "text",
    text: "✦ 試穿",
    flex: 0,
    size: "xs",
    weight: "bold",
    color: CARD_COLOR.onPrimary,
  });
});

Deno.test("a corner tag is the try-on pill's glass, cut square, pinned to the top-left corner", () => {
  // deno-lint-ignore no-explicit-any
  const corner = cornerTag("顯瘦") as any;

  assertEquals(corner.position, "absolute");
  assertEquals(corner.offsetTop, "8px");
  assertEquals(corner.offsetStart, "8px");
  assertEquals(corner.backgroundColor, CARD_COLOR.glass);
  assertEquals(corner.borderColor, CARD_COLOR.glassStroke);
  assertEquals(corner.cornerRadius, "4px");
  assertEquals(corner.maxWidth, undefined);
  assertEquals(corner.contents[0].text, "顯瘦");
  assertEquals(corner.contents[0].color, CARD_COLOR.onPrimary);
});

Deno.test("a tag label longer than eight characters is cut to seven and an ellipsis", () => {
  assertEquals(clampTagLabel("你的衣櫃"), "你的衣櫃");
  assertEquals(clampTagLabel("寬鬆好搭又顯瘦的"), "寬鬆好搭又顯瘦的");
  assertEquals(clampTagLabel("寬鬆好搭又顯瘦的高腰直筒"), "寬鬆好搭又顯瘦…");
});

Deno.test("a source line is small bold ink, one line", () => {
  assertEquals(sourceLine("UNIQLO"), {
    type: "text",
    text: "UNIQLO",
    size: "xxs",
    weight: "bold",
    color: CARD_COLOR.primary,
    maxLines: 1,
  });
});

const media = { type: "image", url: "https://img.example/p.jpg", size: "full", aspectRatio: "4:5", aspectMode: "cover" };
const overlay = [{ type: "text", text: "白襯衫" }];

Deno.test("an overlay hero keeps the media first, then the overlay", () => {
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ media, overlay, paddingAll: "14px", paddingTop: "72px" }) as any;

  // Flex refuses an absolutely positioned first child, so the media must lead.
  assertEquals(hero.contents[0], media);
  assertEquals(hero.paddingAll, "0px");
  assertEquals(hero.contents[1].position, "absolute");
  assertEquals(hero.contents[1].offsetBottom, "0px");
  assertEquals(hero.contents[1].offsetStart, "0px");
  assertEquals(hero.contents[1].offsetEnd, "0px");
  assertEquals(hero.contents[1].paddingAll, "14px");
  assertEquals(hero.contents[1].paddingTop, "72px");
  assertEquals(hero.contents[1].contents, overlay);
});

Deno.test("the scrim darkens from the bottom up through a midpoint", () => {
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ media, overlay, paddingAll: "16px", paddingTop: "80px" }) as any;

  // 0deg runs bottom to top, so startColor is the bottom edge.
  assertEquals(hero.contents[1].background, {
    type: "linearGradient",
    angle: "0deg",
    startColor: CARD_COLOR.scrimStrong,
    centerColor: CARD_COLOR.scrimMid,
    centerPosition: "55%",
    endColor: CARD_COLOR.scrimClear,
  });
  assertEquals(hero.contents.length, 2);
});

Deno.test("an overlay hero is tappable only when given an action", () => {
  const tap = { type: "uri", label: "商品詳情", uri: "https://liff.example/product/p1" };
  const base = { media, overlay, paddingAll: "16px", paddingTop: "80px" };
  // deno-lint-ignore no-explicit-any
  assertEquals((overlayHero({ ...base, action: tap }) as any).action, tap);
  assertEquals("action" in overlayHero(base), false);
});
