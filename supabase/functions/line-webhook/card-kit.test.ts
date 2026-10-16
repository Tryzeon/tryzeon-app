import { assertEquals } from "@std/assert";
import {
  CARD_COLOR,
  cornerTag,
  detailDot,
  overlayHero,
  pillButton,
  primaryButton,
  tag,
} from "./card-kit.ts";

const action = { type: "postback", label: "試穿", data: "a=tryon_product&pid=p1" };

Deno.test("the palette is the design system's, plus translucent steps for type on a photo", () => {
  assertEquals(CARD_COLOR, {
    primary: "#1A1A1A",
    onPrimary: "#FFFFFF",
    muted: "#9E9E9E",
    outline: "#E5E5E5",
    surface: "#FFFFFF",
    surfaceVariant: "#F7F7F7",
    onImage: "#FFFFFF",
    onImageMuted: "#FFFFFFCC",
    onImageFaint: "#FFFFFF99",
    chip: "#FFFFFFF2",
    scrimStrong: "#000000D6",
    scrimMid: "#0000008C",
    scrimClear: "#00000000",
  });
});

Deno.test("a button's action is on the box, so the whole button is tappable", () => {
  for (const button of [primaryButton("前往購買", action), pillButton("✦ 試穿", action)]) {
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

Deno.test("the pill is a near-white capsule with charcoal type, roomier at md", () => {
  // deno-lint-ignore no-explicit-any
  const sm = pillButton("✦ 試穿", action) as any;
  // deno-lint-ignore no-explicit-any
  const md = pillButton("✦ 試穿整套", action, "md") as any;

  assertEquals(sm.backgroundColor, CARD_COLOR.chip);
  assertEquals(sm.cornerRadius, "100px");
  assertEquals(sm.margin, "12px");
  assertEquals(sm.paddingAll, "10px");
  assertEquals(md.paddingAll, "12px");
  assertEquals(sm.contents[0], {
    type: "text",
    text: "✦ 試穿",
    size: "sm",
    weight: "bold",
    color: CARD_COLOR.primary,
    align: "center",
  });
  assertEquals(md.contents[0].size, "md");
});

Deno.test("a light tag is a white capsule, a dark one a charcoal capsule", () => {
  // deno-lint-ignore no-explicit-any
  const light = tag("顯瘦", "light") as any;
  // deno-lint-ignore no-explicit-any
  const dark = tag("你的衣櫃", "dark") as any;

  assertEquals(light.backgroundColor, CARD_COLOR.chip);
  assertEquals(light.contents[0].color, CARD_COLOR.primary);
  assertEquals(dark.backgroundColor, CARD_COLOR.primary);
  assertEquals(dark.contents[0].color, CARD_COLOR.onPrimary);
  assertEquals(light.cornerRadius, "100px");
  assertEquals(light.flex, 0);
});

Deno.test("a corner tag is the same tag pinned to the top-left corner", () => {
  // deno-lint-ignore no-explicit-any
  const corner = cornerTag("顯瘦", "light") as any;

  assertEquals(corner.position, "absolute");
  assertEquals(corner.offsetTop, "8px");
  assertEquals(corner.offsetStart, "8px");
  assertEquals(corner.contents, (tag("顯瘦", "light") as { contents: unknown }).contents);
});

Deno.test("the detail dot is a small capsule pinned to the top-right corner", () => {
  // deno-lint-ignore no-explicit-any
  const dot = detailDot() as any;

  assertEquals(dot.position, "absolute");
  assertEquals(dot.offsetTop, "8px");
  assertEquals(dot.offsetEnd, "8px");
  assertEquals(dot.width, "22px");
  assertEquals(dot.height, "22px");
  assertEquals(dot.contents[0].text, "›");
});

const media = { type: "image", url: "https://img.example/p.jpg", size: "full", aspectRatio: "4:5", aspectMode: "cover" };
const overlay = [{ type: "text", text: "白襯衫" }];

Deno.test("an overlay hero keeps the media first, then the overlay, then the badges", () => {
  const badge = detailDot();
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ media, overlay, badges: [badge], paddingAll: "14px", paddingTop: "72px" }) as any;

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
  assertEquals(hero.contents[2], badge);
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
