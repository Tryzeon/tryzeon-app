/** Every value is a design-system token, or a translucent step of one for type and controls laid over a photo. */
export const CARD_COLOR = {
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
  scrimStrong: "#000000D6",
  scrimMid: "#0000008C",
  scrimClear: "#00000000",
} as const;

/**
 * Flex's `button` offers three fixed styles and controls neither corner radius
 * nor type, so both buttons are boxes carrying an `action`, tappable across the
 * whole area. The action must sit on the box: on the inner text only the glyphs
 * would be tappable.
 */
export function primaryButton(label: string, action: object): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    backgroundColor: CARD_COLOR.primary,
    cornerRadius: "8px",
    paddingAll: "12px",
    contents: [{
      type: "text",
      text: label,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.onPrimary,
      align: "center",
    }],
  };
}

const PILL_PADDING = {
  compact: { vertical: "6px", start: "10px", end: "11px", text: "xs" },
  regular: { vertical: "10px", start: "16px", end: "16px", text: "sm" },
} as const;

/**
 * The action sits on a transparent frame around the pill, so the tap area
 * reaches 44px while the pill keeps its size. The label is `flex: 0`: in a
 * horizontal box it would default to 1, and LINE for PC sizes a box to its
 * content, so a flexible label collapses to nothing.
 */
export function whitePill(label: string, action: object, size: "compact" | "regular"): object {
  const pad = PILL_PADDING[size];
  return {
    type: "box",
    layout: "vertical",
    action,
    flex: 0,
    paddingAll: "4px",
    contents: [{
      type: "box",
      layout: "horizontal",
      backgroundColor: CARD_COLOR.surface,
      cornerRadius: "100px",
      paddingTop: pad.vertical,
      paddingBottom: pad.vertical,
      paddingStart: pad.start,
      paddingEnd: pad.end,
      contents: [{ type: "text", text: label, flex: 0, size: pad.text, weight: "bold", color: CARD_COLOR.primary }],
    }],
  };
}

/** The line above a card's name saying where the piece comes from: a store, or the wardrobe. */
export function sourceLine(text: string): object {
  return { type: "text", text, size: "xxs", weight: "bold", color: CARD_COLOR.primary, maxLines: 1 };
}

const MAX_TAG_CHARS = 8;

/**
 * A model-written label has only the prompt bounding its length. It is cut here
 * rather than capped with `maxWidth`, which LINE for PC renders as a fixed-width
 * box, stretching even a short tag across the photo.
 */
export function clampTagLabel(label: string): string {
  const chars = Array.from(label);
  return chars.length > MAX_TAG_CHARS ? `${chars.slice(0, MAX_TAG_CHARS - 1).join("")}…` : label;
}

/**
 * A label laid on a photo's top-left corner. The stroke keeps the white pill
 * visible on a white product shot or the cutout backdrop.
 */
export function cornerTag(label: string): object {
  return {
    type: "box",
    layout: "vertical",
    position: "absolute",
    offsetTop: "8px",
    offsetStart: "8px",
    backgroundColor: CARD_COLOR.surface,
    borderColor: CARD_COLOR.tagStroke,
    borderWidth: "1px",
    cornerRadius: "100px",
    paddingTop: "2px",
    paddingBottom: "2px",
    paddingStart: "8px",
    paddingEnd: "8px",
    contents: [{
      type: "text",
      text: clampTagLabel(label),
      size: "xxs",
      weight: "bold",
      color: CARD_COLOR.primary,
    }],
  };
}

export interface OverlayHeroOptions {
  media: object;
  overlay: object[];
  corner?: object[];
  action?: object;
  paddingAll: string;
  paddingTop: string;
}

/**
 * Media with text laid over its bottom edge on a gradient, so light and busy
 * photos alike keep the type legible. The media leads because Flex refuses an
 * absolutely positioned first child.
 */
export function overlayHero(opts: OverlayHeroOptions): object {
  return {
    type: "box",
    layout: "vertical",
    paddingAll: "0px",
    ...(opts.action ? { action: opts.action } : {}),
    contents: [
      opts.media,
      {
        type: "box",
        layout: "vertical",
        position: "absolute",
        offsetBottom: "0px",
        offsetStart: "0px",
        offsetEnd: "0px",
        paddingAll: opts.paddingAll,
        paddingTop: opts.paddingTop,
        background: {
          type: "linearGradient",
          angle: "0deg",
          startColor: CARD_COLOR.scrimStrong,
          centerColor: CARD_COLOR.scrimMid,
          centerPosition: "55%",
          endColor: CARD_COLOR.scrimClear,
        },
        contents: opts.overlay,
      },
      ...(opts.corner ?? []),
    ],
  };
}

export interface PickView {
  imageUrl: string;
  highlight?: string;
  source?: string;
  name: string;
  value: { text: string; muted: boolean };
  tryonAction: object;
  detailAction?: object;
}

/**
 * One card for a store product and a wardrobe item alike: the photo is the
 * card and the words sit on its scrim. The backdrop shows through a
 * transparent cutout instead of LINE's dark chat surface.
 */
export function pickBubble(view: PickView): object {
  const value = view.value.muted
    ? { type: "text", text: view.value.text, size: "xs", color: CARD_COLOR.onImageMuted, gravity: "center", flex: 1 }
    : {
      type: "text",
      text: view.value.text,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.onImage,
      gravity: "center",
      flex: 1,
    };
  return {
    type: "bubble",
    size: "kilo",
    hero: overlayHero({
      media: {
        type: "image",
        url: view.imageUrl,
        size: "full",
        aspectRatio: "15:22",
        aspectMode: "cover",
        backgroundColor: CARD_COLOR.cutoutBackdrop,
      },
      overlay: [
        ...(view.source
          ? [{ type: "text", text: view.source, size: "xxs", color: CARD_COLOR.onImageMuted, maxLines: 1 }]
          : []),
        {
          type: "text",
          ...(view.source ? { margin: "2px" } : {}),
          text: view.name,
          size: "sm",
          color: CARD_COLOR.onImage,
          maxLines: 1,
        },
        {
          type: "box",
          layout: "horizontal",
          margin: "4px",
          contents: [value, whitePill("✦ 試穿", view.tryonAction, "compact")],
        },
      ],
      corner: view.highlight ? [cornerTag(view.highlight)] : undefined,
      action: view.detailAction,
      paddingAll: "12px",
      paddingTop: "44px",
    }),
  };
}
