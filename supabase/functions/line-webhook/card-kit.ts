/** Every value is a design-system token, or a translucent step of one for type and controls laid over a photo. */
export const CARD_COLOR = {
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

/**
 * The app's frosted try-on pill, as close as Flex gets without a blur: ink at 70%
 * under a faint white stroke, so its white type holds 4.5:1 even over a white
 * photo. The action sits on a transparent frame around it, so the tap area
 * reaches 44px while the pill keeps its size. The label is `flex: 0`: in a
 * horizontal box it would default to 1, and LINE for PC sizes an absolute box to
 * its content, so a flexible label collapses to nothing.
 */
export function tryonChip(action: object): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    position: "absolute",
    offsetBottom: "0px",
    offsetEnd: "0px",
    paddingAll: "8px",
    contents: [{
      type: "box",
      layout: "horizontal",
      backgroundColor: CARD_COLOR.glass,
      borderColor: CARD_COLOR.glassStroke,
      borderWidth: "1px",
      cornerRadius: "100px",
      paddingTop: "6px",
      paddingBottom: "6px",
      paddingStart: "10px",
      paddingEnd: "11px",
      contents: [{ type: "text", text: "✦ 試穿", flex: 0, size: "xs", weight: "bold", color: CARD_COLOR.onPrimary }],
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
 * A label laid on a photo's top-left corner: the try-on pill's glass, cut
 * square so it reads as a tag rather than a control.
 */
export function cornerTag(label: string): object {
  return {
    type: "box",
    layout: "vertical",
    position: "absolute",
    offsetTop: "8px",
    offsetStart: "8px",
    backgroundColor: CARD_COLOR.glass,
    borderColor: CARD_COLOR.glassStroke,
    borderWidth: "1px",
    cornerRadius: "4px",
    paddingTop: "2px",
    paddingBottom: "2px",
    paddingStart: "7px",
    paddingEnd: "7px",
    contents: [{
      type: "text",
      text: clampTagLabel(label),
      size: "xxs",
      weight: "bold",
      color: CARD_COLOR.onPrimary,
    }],
  };
}

export interface OverlayHeroOptions {
  media: object;
  overlay: object[];
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
    ],
  };
}
