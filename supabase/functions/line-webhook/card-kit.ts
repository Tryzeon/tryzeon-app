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
  scrim: "#00000080",
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
export function whitePill(
  label: string,
  action: object,
  size: "compact" | "regular",
): object {
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
      contents: [{
        type: "text",
        text: label,
        flex: 0,
        size: pad.text,
        weight: "bold",
        color: CARD_COLOR.primary,
      }],
    }],
  };
}

/** The line above a card's name saying where the piece comes from: a store, or the wardrobe. */
export function sourceLine(text: string): object {
  return {
    type: "text",
    text,
    size: "xxs",
    weight: "bold",
    color: CARD_COLOR.primary,
    maxLines: 1,
  };
}

const MAX_TAG_CHARS = 8;

/**
 * A model-written label has only the prompt bounding its length. It is cut here
 * rather than capped with `maxWidth`, which LINE for PC renders as a fixed-width
 * box, stretching even a short tag across the photo.
 */
export function clampTagLabel(label: string): string {
  const chars = Array.from(label);
  return chars.length > MAX_TAG_CHARS
    ? `${chars.slice(0, MAX_TAG_CHARS - 1).join("")}…`
    : label;
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
  /** In px, from the media's foot. The words sit low enough to stay on it. */
  scrimHeight: number;
}

/**
 * Media with text laid over its bottom edge on a scrim, so light and busy
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
      scrim(opts.scrimHeight),
      {
        type: "box",
        layout: "vertical",
        position: "absolute",
        offsetBottom: "0px",
        offsetStart: "0px",
        offsetEnd: "0px",
        paddingAll: opts.paddingAll,
        contents: opts.overlay,
      },
      ...(opts.corner ?? []),
    ],
  };
}

const SCRIM_ALPHA = parseInt(CARD_COLOR.scrim.slice(7), 16);
const SCRIM_FADE_END = 0.8;
const SCRIM_LAYERS = 6;

/**
 * A Flex gradient holds at most three stops, and boxes stacked edge to edge
 * leave a hairline at each seam once LINE scales the bubble to the screen. So
 * the scrim overlaps layers anchored to the foot, each ramping in from clear:
 * every edge they have is a clear one, and together they trace an S-curve that
 * is flat where it starts and where it meets the full scrim.
 */
function scrim(height: number): object {
  let clear = 1;
  const layers = Array.from({ length: SCRIM_LAYERS }, (_, k) => {
    const top = SCRIM_FADE_END * k / SCRIM_LAYERS;
    const rampEnd = SCRIM_FADE_END * (k + 1) / SCRIM_LAYERS;
    const s = (k + 1) / SCRIM_LAYERS;
    const target = (SCRIM_ALPHA / 255) * s * s * (3 - 2 * s);
    const alpha = Math.round(255 * (1 - (1 - target) / clear));
    clear *= 1 - alpha / 255;
    const color = scrimColor(alpha);
    return {
      type: "box",
      layout: "vertical",
      contents: [],
      ...(k === 0 ? { flex: 1 } : {
        position: "absolute",
        offsetBottom: "0px",
        offsetStart: "0px",
        offsetEnd: "0px",
        height: percent(1 - top),
      }),
      background: {
        type: "linearGradient",
        angle: "0deg",
        startColor: color,
        centerColor: color,
        centerPosition: percent((1 - rampEnd) / (1 - top)),
        endColor: scrimColor(0),
      },
    };
  });
  return {
    type: "box",
    layout: "vertical",
    position: "absolute",
    offsetBottom: "0px",
    offsetStart: "0px",
    offsetEnd: "0px",
    height: `${height}px`,
    contents: layers,
  };
}

function scrimColor(alpha: number): string {
  return `${CARD_COLOR.scrim.slice(0, 7)}${
    alpha.toString(16).padStart(2, "0").toUpperCase()
  }`;
}

function percent(fraction: number): string {
  return `${Number((fraction * 100).toFixed(2))}%`;
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
    ? {
      type: "text",
      text: view.value.text,
      size: "xs",
      color: CARD_COLOR.onImageMuted,
      gravity: "center",
      flex: 1,
    }
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
          ? [{
            type: "text",
            text: view.source,
            size: "xxs",
            color: CARD_COLOR.onImageMuted,
            maxLines: 1,
          }]
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
      scrimHeight: 120,
    }),
  };
}
