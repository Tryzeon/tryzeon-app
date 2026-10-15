/** Every value is a token from `docs/ui-design-system.md`, or a translucent step of one for type laid over a photo. */
export const CARD_COLOR = {
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

export function secondaryButton(label: string, action: object): object {
  return {
    type: "box",
    layout: "vertical",
    action,
    borderWidth: "1px",
    borderColor: CARD_COLOR.outline,
    cornerRadius: "8px",
    paddingAll: "12px",
    contents: [{
      type: "text",
      text: label,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.primary,
      align: "center",
    }],
  };
}

/**
 * A photo with text laid over its bottom edge on a gradient, so light and busy
 * photos alike keep the type legible. The photo leads because Flex refuses an
 * absolutely positioned first child.
 */
export function overlayHero(opts: { image: object; overlay: object[]; action?: object }): object {
  return {
    type: "box",
    layout: "vertical",
    paddingAll: "0px",
    ...(opts.action ? { action: opts.action } : {}),
    contents: [
      opts.image,
      {
        type: "box",
        layout: "vertical",
        position: "absolute",
        offsetBottom: "0px",
        offsetStart: "0px",
        offsetEnd: "0px",
        paddingAll: "16px",
        paddingTop: "48px",
        background: {
          type: "linearGradient",
          angle: "0deg",
          startColor: CARD_COLOR.scrim,
          endColor: CARD_COLOR.scrimClear,
        },
        contents: opts.overlay,
      },
    ],
  };
}
