/** Every value is a design-system token, or a translucent step of one for type and controls laid over a photo. */
export const CARD_COLOR = {
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

export function pillButton(label: string, action: object, size: "sm" | "md" = "sm"): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    margin: "12px",
    backgroundColor: CARD_COLOR.chip,
    cornerRadius: "100px",
    paddingAll: size === "md" ? "12px" : "10px",
    contents: [{
      type: "text",
      text: label,
      size,
      weight: "bold",
      color: CARD_COLOR.primary,
      align: "center",
    }],
  };
}

export type TagTone = "light" | "dark";

export function tag(label: string, tone: TagTone): object {
  return {
    type: "box",
    layout: "vertical",
    flex: 0,
    backgroundColor: tone === "light" ? CARD_COLOR.chip : CARD_COLOR.primary,
    cornerRadius: "100px",
    paddingTop: "4px",
    paddingBottom: "4px",
    paddingStart: "9px",
    paddingEnd: "9px",
    contents: [{
      type: "text",
      text: label,
      size: "xxs",
      weight: "bold",
      color: tone === "light" ? CARD_COLOR.primary : CARD_COLOR.onPrimary,
    }],
  };
}

export function cornerTag(label: string, tone: TagTone): object {
  return { ...tag(label, tone), position: "absolute", offsetTop: "8px", offsetStart: "8px" };
}

/** A tappable photo looks like any other photo, so the ones that open a page say so. */
export function detailDot(): object {
  return {
    type: "box",
    layout: "vertical",
    position: "absolute",
    offsetTop: "8px",
    offsetEnd: "8px",
    width: "22px",
    height: "22px",
    cornerRadius: "100px",
    backgroundColor: CARD_COLOR.chip,
    justifyContent: "center",
    contents: [{ type: "text", text: "›", size: "sm", weight: "bold", color: CARD_COLOR.primary, align: "center" }],
  };
}

export interface OverlayHeroOptions {
  media: object;
  overlay: object[];
  badges?: object[];
  action?: object;
  paddingAll: string;
  paddingTop: string;
}

/**
 * Media with text laid over its bottom edge on a gradient, so light and busy
 * photos alike keep the type legible. The media leads because Flex refuses an
 * absolutely positioned first child; the badges follow for the same reason.
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
      ...(opts.badges ?? []),
    ],
  };
}
