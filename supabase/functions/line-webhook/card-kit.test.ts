import { assertAlmostEquals, assertEquals } from "@std/assert";
import {
  CARD_COLOR,
  clampTagLabel,
  cornerTag,
  overlayHero,
  pickBubble,
  type PickView,
  primaryButton,
  sourceLine,
  whitePill,
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
    onImage: "#FFFFFF",
    onImageMuted: "#FFFFFFCC",
    cutoutBackdrop: "#EBE7E0",
    tagStroke: "#0000001F",
    scrim: "#00000080",
  });
});

Deno.test("a button's action is on the box, so the whole button is tappable", () => {
  for (const button of [primaryButton("前往購買", action), whitePill("✦ 試穿", action, "compact")]) {
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

Deno.test("a white pill is a filled white capsule with ink type, carrying its action on the box", () => {
  for (const size of ["compact", "regular"] as const) {
    // deno-lint-ignore no-explicit-any
    const frame = whitePill("✦ 試穿", action, size) as any;
    const pill = frame.contents[0];

    assertEquals(frame.action, action);
    assertEquals(frame.flex, 0);
    assertEquals(frame.position, undefined);
    assertEquals(frame.backgroundColor, undefined);
    assertEquals(pill.backgroundColor, "#FFFFFF");
    assertEquals(pill.cornerRadius, "100px");
    assertEquals(pill.action, undefined);
    assertEquals(pill.contents[0].text, "✦ 試穿");
    assertEquals(pill.contents[0].flex, 0);
    assertEquals(pill.contents[0].weight, "bold");
    assertEquals(pill.contents[0].color, CARD_COLOR.primary);
  }
});

Deno.test("a regular pill is taller and larger-type than a compact one", () => {
  // deno-lint-ignore no-explicit-any
  const compact = (whitePill("✦ 試穿", action, "compact") as any).contents[0];
  // deno-lint-ignore no-explicit-any
  const regular = (whitePill("✦ 試穿整套", action, "regular") as any).contents[0];

  assertEquals(compact.contents[0].size, "xs");
  assertEquals(regular.contents[0].size, "sm");
  assertEquals(compact.paddingTop, "6px");
  assertEquals(regular.paddingTop, "10px");
});

Deno.test("a corner tag is a white pill with a hairline stroke, pinned to the top-left corner", () => {
  // deno-lint-ignore no-explicit-any
  const corner = cornerTag("顯瘦") as any;

  assertEquals(corner.position, "absolute");
  assertEquals(corner.offsetTop, "8px");
  assertEquals(corner.offsetStart, "8px");
  assertEquals(corner.backgroundColor, "#FFFFFF");
  assertEquals(corner.borderColor, CARD_COLOR.tagStroke);
  assertEquals(corner.borderWidth, "1px");
  assertEquals(corner.cornerRadius, "100px");
  assertEquals(corner.maxWidth, undefined);
  assertEquals(corner.contents[0].text, "顯瘦");
  assertEquals(corner.contents[0].color, CARD_COLOR.primary);
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

// deno-lint-ignore no-explicit-any
const layersOf = (hero: any) => hero.contents[1].contents;
const alphaOf = (color: string) => parseInt(color.slice(7), 16) / 255;

Deno.test("an overlay hero keeps the media first, then the scrim, then the words over it", () => {
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ media, overlay, paddingAll: "14px", scrimHeight: 192 }) as any;

  // Flex refuses an absolutely positioned first child, so the media must lead.
  assertEquals(hero.contents[0], media);
  assertEquals(hero.paddingAll, "0px");
  assertEquals(hero.contents[1].position, "absolute");
  assertEquals(hero.contents[1].offsetBottom, "0px");
  assertEquals(hero.contents[1].offsetStart, "0px");
  assertEquals(hero.contents[1].offsetEnd, "0px");
  assertEquals(hero.contents[1].height, "192px");
  assertEquals(hero.contents[2], {
    type: "box",
    layout: "vertical",
    position: "absolute",
    offsetBottom: "0px",
    offsetStart: "0px",
    offsetEnd: "0px",
    paddingAll: "14px",
    contents: overlay,
  });
});

Deno.test("every scrim layer rises from the foot and enters from clear, so no edge of one shows", () => {
  const layers = layersOf(overlayHero({ media, overlay, paddingAll: "16px", scrimHeight: 104 }));

  // Flex refuses an absolutely positioned first child, so the tallest layer fills the scrim in flow.
  assertEquals(layers[0].flex, 1);
  assertEquals("position" in layers[0], false);
  // deno-lint-ignore no-explicit-any
  for (const layer of layers.slice(1) as any[]) {
    assertEquals(layer.position, "absolute");
    assertEquals(layer.offsetBottom, "0px");
    assertEquals(layer.offsetStart, "0px");
    assertEquals(layer.offsetEnd, "0px");
  }
  // deno-lint-ignore no-explicit-any
  for (const { background } of layers as any[]) {
    assertEquals(background.angle, "0deg");
    assertEquals(alphaOf(background.endColor), 0);
    assertEquals(background.centerColor, background.startColor);
  }
});

Deno.test("each layer's ramp ends where the next one's begins", () => {
  const layers = layersOf(overlayHero({ media, overlay, paddingAll: "16px", scrimHeight: 104 }));
  const height = (i: number) => i === 0 ? 100 : parseFloat(layers[i].height);

  for (let i = 0; i + 1 < layers.length; i++) {
    const rampEnd = height(i) * parseFloat(layers[i].background.centerPosition) / 100;
    assertAlmostEquals(rampEnd, height(i + 1), 0.05);
  }
});

Deno.test("the layers build an S-curve from clear to the full scrim", () => {
  const layers = layersOf(overlayHero({ media, overlay, paddingAll: "16px", scrimHeight: 104 }));
  let clear = 1;
  const knots = [0];
  // deno-lint-ignore no-explicit-any
  for (const { background } of layers as any[]) {
    clear *= 1 - alphaOf(background.startColor);
    knots.push(1 - clear);
  }
  const steps = knots.slice(1).map((alpha, i) => alpha - knots[i]);

  assertAlmostEquals(knots.at(-1)!, alphaOf(CARD_COLOR.scrim), 1 / 255);
  assertEquals(steps.every((step) => step > 0), true);
  assertEquals(steps[0] < steps[steps.length / 2], true);
  assertEquals(steps.at(-1)! < steps[steps.length / 2], true);
});

Deno.test("an overlay hero is tappable only when given an action", () => {
  const tap = { type: "uri", label: "商品詳情", uri: "https://liff.example/product/p1" };
  const base = { media, overlay, paddingAll: "16px", scrimHeight: 104 };
  // deno-lint-ignore no-explicit-any
  assertEquals((overlayHero({ ...base, action: tap }) as any).action, tap);
  assertEquals("action" in overlayHero(base), false);
});

Deno.test("an overlay hero appends corner children after the words", () => {
  const tag = cornerTag("顯瘦");
  // deno-lint-ignore no-explicit-any
  const hero = overlayHero({ media, overlay, corner: [tag], paddingAll: "12px", scrimHeight: 120 }) as any;

  assertEquals(hero.contents.length, 4);
  assertEquals(hero.contents[0], media);
  assertEquals(hero.contents[3], tag);
});

const tryon = { type: "postback", label: "試穿", data: "a=tryon_product&pid=p1", displayText: "試穿「白襯衫」" };
const detail = { type: "uri", label: "商品詳情", uri: "https://liff.example/product/p1" };
const view = (over: Partial<PickView> = {}): PickView => ({
  imageUrl: "https://img.example/p.jpg",
  source: "UNIQLO",
  name: "白襯衫",
  value: { text: "NT$1,200", muted: false },
  tryonAction: tryon,
  ...over,
});

Deno.test("a pick bubble is a hero-only 15:22 cover photo on the warm backdrop", () => {
  // deno-lint-ignore no-explicit-any
  const bubble = pickBubble(view()) as any;

  assertEquals(bubble.type, "bubble");
  assertEquals(bubble.size, "kilo");
  assertEquals(bubble.body, undefined);
  assertEquals(bubble.footer, undefined);
  assertEquals(bubble.hero.contents[0], {
    type: "image",
    url: "https://img.example/p.jpg",
    size: "full",
    aspectRatio: "15:22",
    aspectMode: "cover",
    backgroundColor: CARD_COLOR.cutoutBackdrop,
  });
});

Deno.test("a pick bubble's overlay reads source, a one-line name, then the value beside the try-on pill", () => {
  // deno-lint-ignore no-explicit-any
  const hero = (pickBubble(view()) as any).hero;
  const overlay = hero.contents[2];
  const [source, name, row] = overlay.contents;

  assertEquals(overlay.paddingAll, "12px");
  assertEquals(hero.contents[1].height, "120px");
  assertEquals(source.text, "UNIQLO");
  assertEquals(source.color, CARD_COLOR.onImageMuted);
  assertEquals(source.maxLines, 1);
  assertEquals(name.text, "白襯衫");
  assertEquals(name.color, CARD_COLOR.onImage);
  assertEquals(name.maxLines, 1);
  assertEquals(row.layout, "horizontal");
  assertEquals(row.contents[0].text, "NT$1,200");
  assertEquals(row.contents[0].size, "sm");
  assertEquals(row.contents[0].weight, "bold");
  assertEquals(row.contents[0].color, CARD_COLOR.onImage);
  assertEquals(row.contents[1], whitePill("✦ 試穿", tryon, "compact"));
});

Deno.test("a muted value is small and dimmed, not bold", () => {
  // deno-lint-ignore no-explicit-any
  const overlay = (pickBubble(view({ value: { text: "已擁有", muted: true } })) as any).hero.contents[2];
  const value = overlay.contents[2].contents[0];

  assertEquals(value.text, "已擁有");
  assertEquals(value.size, "xs");
  assertEquals(value.weight, undefined);
  assertEquals(value.color, CARD_COLOR.onImageMuted);
});

Deno.test("a pick bubble is tappable only with a detail action, and tagged only with a highlight", () => {
  // deno-lint-ignore no-explicit-any
  const plain = pickBubble(view()) as any;
  // deno-lint-ignore no-explicit-any
  const full = pickBubble(view({ detailAction: detail, highlight: "顯瘦" })) as any;

  assertEquals("action" in plain.hero, false);
  assertEquals(plain.hero.contents.length, 3);
  assertEquals(full.hero.action, detail);
  assertEquals(full.hero.contents[3], cornerTag("顯瘦"));
});

Deno.test("a pick bubble with no source skips that line", () => {
  // deno-lint-ignore no-explicit-any
  const overlay = (pickBubble(view({ source: undefined })) as any).hero.contents[2];
  assertEquals(overlay.contents.length, 2);
  assertEquals(overlay.contents[0].text, "白襯衫");
  assertEquals("margin" in overlay.contents[0], false);
});
