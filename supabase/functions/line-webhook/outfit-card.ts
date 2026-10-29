import type { ItemRef } from "../_shared/chat/index.ts";
import {
  CARD_COLOR,
  cornerTag,
  overlayHero,
  sourceLine,
  whitePill,
} from "./card-kit.ts";
import {
  type LineProduct,
  priceText,
  productDetailUrl,
} from "./product-card.ts";
import { type LineWardrobeItem, tagLine } from "./wardrobe-card.ts";
import { cameraRollChip, messageChip, withQuickReply } from "./quick-reply.ts";
import { outfitTryonPostbackData } from "./postback.ts";

export type OutfitPiece =
  | { kind: "product"; item: LineProduct }
  | { kind: "wardrobe"; item: LineWardrobeItem };

export interface LineOutfit {
  title: string;
  reason?: string;
  pieces: OutfitPiece[];
}

export interface PieceLookup {
  product(id: string): LineProduct | undefined;
  wardrobe(id: string): LineWardrobeItem | undefined;
}

/** Null when any piece is missing: a look renders, and is tried on, only whole. */
export function resolveOutfitPieces(
  pieces: ItemRef[],
  find: PieceLookup,
): OutfitPiece[] | null {
  const resolved: OutfitPiece[] = [];
  for (const { type, id } of pieces) {
    if (type === "product") {
      const item = find.product(id);
      if (!item) return null;
      resolved.push({ kind: "product", item });
    } else {
      const item = find.wardrobe(id);
      if (!item) return null;
      resolved.push({ kind: "wardrobe", item });
    }
  }
  return resolved.length > 0 ? resolved : null;
}

export function outfitPieceRefs(pieces: OutfitPiece[]): ItemRef[] {
  return pieces.map((piece) => ({
    type: piece.kind,
    id: piece.item.id,
  }));
}

export function outfitTryonAction(outfit: LineOutfit): object {
  return {
    type: "postback",
    label: "試穿整套",
    data: outfitTryonPostbackData(outfitPieceRefs(outfit.pieces)),
    displayText: "試穿整套",
  };
}

export interface OutfitPurchase {
  count: number;
  total: number;
}

/** Null when every piece is already in the wardrobe. */
export function outfitPurchase(pieces: OutfitPiece[]): OutfitPurchase | null {
  const prices = pieces.flatMap((piece) =>
    piece.kind === "product" ? [piece.item.price] : []
  );
  if (prices.length === 0) return null;
  return {
    count: prices.length,
    total: prices.reduce((sum, price) => sum + price, 0),
  };
}

/** "共" when every piece is for sale; "再買" when the wardrobe already covers part of the look. */
export function purchaseCountText(
  purchase: OutfitPurchase,
  pieceCount: number,
): string {
  return purchase.count < pieceCount
    ? `再買 ${purchase.count} 件`
    : `共 ${purchase.count} 件`;
}

function purchaseLines(pieces: OutfitPiece[]): object[] {
  const purchase = outfitPurchase(pieces);
  if (purchase === null) {
    return [{
      type: "text",
      text: "全部來自你的衣櫃",
      size: "sm",
      color: CARD_COLOR.onImage,
    }];
  }
  return [
    {
      type: "text",
      text: purchaseCountText(purchase, pieces.length),
      size: "xs",
      color: CARD_COLOR.onImageMuted,
    },
    {
      type: "text",
      margin: "2px",
      text: priceText(purchase.total),
      size: "md",
      weight: "bold",
      color: CARD_COLOR.onImage,
    },
  ];
}

/**
 * Each image's ratio is its cell's shape in a mega bubble (300px wide, 2px
 * gutters) whose collage is 400px tall for every look, so a carousel's looks
 * line up whatever their piece count. A trio sets a 3fr lead beside a 2fr
 * column of two; a pair halves the width. A ratio that matches the cell is
 * what makes `cover` fill it without letterboxing.
 */
const CELL_RATIO = {
  half: "149:400",
  lead: "179:400",
  stacked: "119:199",
} as const;

/**
 * The photos carry no prices: the footer totals what is left to buy, and only an
 * owned piece is marked, so an unmarked cell reads as one to buy. A look made
 * only of owned pieces needs no marks: the footer already says so.
 */
function cell(
  piece: OutfitPiece,
  aspectRatio: string,
  labelled: boolean,
  liffUrl: string,
): object {
  const image = {
    type: "image",
    url: piece.item.imageUrl,
    size: "full",
    aspectRatio,
  };
  if (piece.kind === "product") {
    return {
      type: "box",
      layout: "vertical",
      flex: 1,
      action: {
        type: "uri",
        label: "商品詳情",
        uri: productDetailUrl(liffUrl, piece.item.id, piece.item.color.id),
      },
      contents: [{ ...image, aspectMode: "cover" }],
    };
  }
  return {
    type: "box",
    layout: "vertical",
    flex: 1,
    // The backdrop keeps a transparent cutout from showing LINE's dark chat
    // surface through it.
    contents: [
      {
        ...image,
        aspectMode: "cover",
        backgroundColor: CARD_COLOR.cutoutBackdrop,
      },
      ...(labelled ? [cornerTag("衣櫃")] : []),
    ],
  };
}

/** Outerwear leads: it is the layer the look is seen in, and the lead cell is the largest. */
export function collageOrder(pieces: OutfitPiece[]): OutfitPiece[] {
  const lead = pieces.findIndex((piece) =>
    piece.item.garmentType === "outerwear"
  );
  return lead <= 0
    ? pieces
    : [pieces[lead], ...pieces.filter((_, i) => i !== lead)];
}

function collage(pieces: OutfitPiece[], liffUrl: string): object {
  const labelled = pieces.some((piece) => piece.kind === "product");
  const frame = {
    type: "box",
    layout: "horizontal",
    spacing: "xs",
    backgroundColor: CARD_COLOR.surface,
  };
  const ordered = collageOrder(pieces);
  if (ordered.length < 3) {
    return {
      ...frame,
      contents: ordered.map((piece) =>
        cell(piece, CELL_RATIO.half, labelled, liffUrl)
      ),
    };
  }
  const [lead, ...stacked] = ordered;
  return {
    ...frame,
    contents: [
      { ...cell(lead, CELL_RATIO.lead, labelled, liffUrl), flex: 3 },
      {
        type: "box",
        layout: "vertical",
        flex: 2,
        spacing: "xs",
        contents: stacked.map((piece) =>
          cell(piece, CELL_RATIO.stacked, labelled, liffUrl)
        ),
      },
    ],
  };
}

/**
 * The words lie over the collage's foot. A cell's part under the overlay is
 * not tappable: Flex stops a tap at the absolutely positioned overlay.
 */
export function outfitBubble(outfit: LineOutfit, liffUrl: string): object {
  return {
    type: "bubble",
    size: "mega",
    hero: overlayHero({
      media: collage(outfit.pieces, liffUrl),
      overlay: [
        {
          type: "text",
          text: outfit.title,
          size: "lg",
          weight: "bold",
          color: CARD_COLOR.onImage,
          maxLines: 1,
        },
        ...(outfit.reason
          ? [{
            type: "text",
            margin: "4px",
            text: outfit.reason,
            size: "sm",
            color: CARD_COLOR.onImageMuted,
            wrap: true,
            maxLines: 2,
          }]
          : []),
        {
          type: "box",
          layout: "horizontal",
          margin: "md",
          spacing: "md",
          contents: [
            {
              type: "box",
              layout: "vertical",
              flex: 1,
              justifyContent: "center",
              contents: purchaseLines(outfit.pieces),
            },
            whitePill("✦ 試穿整套", outfitTryonAction(outfit), "regular"),
          ],
        },
      ],
      paddingAll: "14px",
      scrimHeight: 192,
    }),
  };
}

function pieceRow(piece: OutfitPiece, liffUrl: string): object {
  const isProduct = piece.kind === "product";
  const source = isProduct ? piece.item.storeName?.toUpperCase() : "你的衣櫃";
  const name = isProduct
    ? piece.item.name
    : tagLine([piece.item.garmentTypeLabel, ...piece.item.tags]);
  return {
    type: "box",
    layout: "horizontal",
    spacing: "md",
    paddingTop: "8px",
    paddingBottom: "8px",
    ...(isProduct
      ? {
        action: {
          type: "uri",
          label: "商品詳情",
          uri: productDetailUrl(liffUrl, piece.item.id, piece.item.color.id),
        },
      }
      : {}),
    contents: [
      {
        type: "box",
        layout: "vertical",
        flex: 0,
        width: "48px",
        height: "48px",
        cornerRadius: "8px",
        backgroundColor: CARD_COLOR.surfaceVariant,
        contents: [{
          type: "image",
          url: piece.item.imageUrl,
          size: "full",
          aspectRatio: "1:1",
          aspectMode: isProduct ? "cover" : "fit",
        }],
      },
      {
        type: "box",
        layout: "vertical",
        flex: 1,
        justifyContent: "center",
        contents: [
          ...(source ? [sourceLine(source)] : []),
          {
            type: "text",
            ...(source ? { margin: "2px" } : {}),
            text: name,
            size: "sm",
            color: CARD_COLOR.mutedText,
          },
        ],
      },
      ...(isProduct
        ? [
          {
            type: "text",
            text: priceText(piece.item.price),
            size: "sm",
            weight: "bold",
            color: CARD_COLOR.primary,
            flex: 0,
            gravity: "center",
          },
          {
            type: "text",
            text: "›",
            size: "sm",
            color: CARD_COLOR.muted,
            flex: 0,
            gravity: "center",
          },
        ]
        : []),
    ],
  };
}

/** The one card that lists its pieces: the try-on has answered "does it look good", so buying comes next. */
export function outfitResultMessage(
  imageUrl: string,
  pieces: OutfitPiece[],
  liffUrl: string,
): object {
  const rows = pieces.flatMap((piece, i) => [
    ...(i > 0 ? [{ type: "separator", color: CARD_COLOR.outline }] : []),
    pieceRow(piece, liffUrl),
  ]);
  return withQuickReply({
    type: "flex",
    altText: "為你試穿了整套穿搭",
    contents: {
      type: "bubble",
      size: "mega",
      hero: {
        type: "image",
        url: imageUrl,
        size: "full",
        aspectRatio: "9:16",
        aspectMode: "cover",
        action: { type: "uri", label: "看大圖", uri: imageUrl },
      },
      body: {
        type: "box",
        layout: "vertical",
        paddingAll: "16px",
        paddingTop: "8px",
        contents: rows,
      },
      styles: { body: { backgroundColor: CARD_COLOR.surface } },
    },
  }, [
    messageChip("再配一套", "再幫我配一套"),
    messageChip("找類似的", "有沒有類似剛剛那套的其他穿搭"),
    cameraRollChip("試我自己的衣服"),
  ]);
}
