import type { ItemRef } from "../_shared/chat/index.ts";
import { CARD_COLOR, cornerTag, overlayHero, pillButton, tag } from "./card-kit.ts";
import { amountText, type LineProduct, productDetailUrl } from "./product-card.ts";
import { type LineWardrobeItem, tagLine } from "./wardrobe-card.ts";
import { cameraRollChip, messageChip, withQuickReply } from "./quick-reply.ts";
import { clampOutfitTitle, outfitTryonPostbackData } from "./postback.ts";

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
export function resolveOutfitPieces(pieces: ItemRef[], find: PieceLookup): OutfitPiece[] | null {
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

export function outfitPieceRefs(outfit: LineOutfit): ItemRef[] {
  return outfit.pieces.map((piece) => ({ type: piece.kind, id: piece.item.id }));
}

export function outfitTryonAction(outfit: LineOutfit): object {
  return {
    type: "postback",
    label: "試穿整套",
    data: outfitTryonPostbackData({ title: outfit.title, pieces: outfitPieceRefs(outfit) }),
    displayText: `試穿「${clampOutfitTitle(outfit.title)}」`,
  };
}

export function outfitMetaText(pieces: OutfitPiece[]): string {
  const prices = pieces.flatMap((piece) => piece.kind === "product" ? [piece.item.price] : []);
  if (prices.length === 0) return "全部來自你的衣櫃";
  const total = `NT$ ${amountText(prices.reduce((sum, price) => sum + price, 0))}`;
  return prices.length === pieces.length
    ? `${pieces.length} 件 · ${total}`
    : `再買 ${prices.length} 件 · ${total}`;
}

export function lookLabel(index: number, total: number): string {
  const two = (n: number) => String(n).padStart(2, "0");
  return `LOOK ${two(index + 1)} / ${two(total)}`;
}

/**
 * Each image's ratio is its cell's shape in a mega bubble (300px wide) whose
 * collage stands about 450px: halves of 149px, a main cell of 199px beside a
 * column of 99px cells stacked two high. A ratio that matches the cell is what
 * makes `cover` fill it without letterboxing.
 */
const CELL_RATIO = { half: "1:3", main: "4:9", side: "4:9" } as const;

function cell(piece: OutfitPiece, aspectRatio: string, liffUrl: string): object {
  if (piece.kind === "product") {
    return {
      type: "box",
      layout: "vertical",
      flex: 1,
      action: { type: "uri", label: "商品詳情", uri: productDetailUrl(liffUrl, piece.item.id) },
      contents: [{ type: "image", url: piece.item.imageUrl, size: "full", aspectRatio, aspectMode: "cover" }],
    };
  }
  return {
    type: "box",
    layout: "vertical",
    flex: 1,
    contents: [
      {
        type: "image",
        url: piece.item.imageUrl,
        size: "full",
        aspectRatio,
        aspectMode: "fit",
        backgroundColor: CARD_COLOR.surfaceVariant,
      },
      cornerTag("你的衣櫃", "dark"),
    ],
  };
}

function collage(pieces: OutfitPiece[], liffUrl: string): object {
  const frame = { type: "box", layout: "horizontal", spacing: "xs", backgroundColor: CARD_COLOR.surface };
  if (pieces.length < 3) {
    return { ...frame, contents: pieces.map((piece) => cell(piece, CELL_RATIO.half, liffUrl)) };
  }
  const [main, ...side] = pieces;
  return {
    ...frame,
    contents: [
      { ...cell(main, CELL_RATIO.main, liffUrl), flex: 2 },
      {
        type: "box",
        layout: "vertical",
        flex: 1,
        spacing: "xs",
        contents: side.map((piece) => cell(piece, CELL_RATIO.side, liffUrl)),
      },
    ],
  };
}

export function outfitBubble(outfit: LineOutfit, index: number, total: number, liffUrl: string): object {
  return {
    type: "bubble",
    size: "mega",
    hero: overlayHero({
      media: collage(outfit.pieces, liffUrl),
      overlay: [
        { type: "text", text: lookLabel(index, total), size: "xxs", weight: "bold", color: CARD_COLOR.onImageMuted },
        { type: "text", margin: "2px", text: outfit.title, size: "xl", weight: "bold", color: CARD_COLOR.onImage },
        ...(outfit.reason
          ? [{
            type: "text",
            margin: "4px",
            text: outfit.reason,
            size: "sm",
            weight: "bold",
            color: CARD_COLOR.onImage,
            wrap: true,
            maxLines: 2,
          }]
          : []),
        {
          type: "text",
          margin: "6px",
          text: outfitMetaText(outfit.pieces),
          size: "xxs",
          color: CARD_COLOR.onImageFaint,
        },
        pillButton("✦ 試穿整套", outfitTryonAction(outfit), "md"),
      ],
      paddingAll: "16px",
      paddingTop: "80px",
    }),
  };
}

function pieceRow(piece: OutfitPiece, liffUrl: string): object {
  const isProduct = piece.kind === "product";
  const kicker = isProduct ? (piece.item.storeName ?? "").toUpperCase() : tagLine(piece.item.tags);
  const name = isProduct ? piece.item.name : piece.item.garmentTypeLabel;
  return {
    type: "box",
    layout: "horizontal",
    spacing: "md",
    paddingTop: "8px",
    paddingBottom: "8px",
    ...(isProduct ? { action: { type: "uri", label: "商品詳情", uri: productDetailUrl(liffUrl, piece.item.id) } } : {}),
    contents: [
      {
        type: "box",
        layout: "vertical",
        flex: 0,
        width: "40px",
        height: "40px",
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
          ...(kicker ? [{ type: "text", text: kicker, size: "xxs", color: CARD_COLOR.muted }] : []),
          { type: "text", text: name, size: "sm", color: CARD_COLOR.primary },
        ],
      },
      ...(isProduct
        ? [
          {
            type: "text",
            text: `$${amountText(piece.item.price)}`,
            size: "sm",
            weight: "bold",
            color: CARD_COLOR.primary,
            flex: 0,
            gravity: "center",
          },
          { type: "text", text: "›", size: "sm", color: CARD_COLOR.muted, flex: 0, gravity: "center" },
        ]
        : [{ type: "box", layout: "vertical", flex: 0, justifyContent: "center", contents: [tag("你的衣櫃", "dark")] }]),
    ],
  };
}

/** The one card that lists its pieces: the try-on has answered "does it look good", so buying comes next. */
export function outfitResultMessage(imageUrl: string, outfit: LineOutfit, liffUrl: string): object {
  const rows = outfit.pieces.flatMap((piece, i) => [
    ...(i > 0 ? [{ type: "separator", color: CARD_COLOR.outline }] : []),
    pieceRow(piece, liffUrl),
  ]);
  return withQuickReply({
    type: "flex",
    altText: `為你試穿了「${clampOutfitTitle(outfit.title)}」`,
    contents: {
      type: "bubble",
      size: "mega",
      hero: overlayHero({
        media: { type: "image", url: imageUrl, size: "full", aspectRatio: "9:16", aspectMode: "cover" },
        overlay: [
          { type: "text", text: "LOOK", size: "xxs", weight: "bold", color: CARD_COLOR.onImageMuted },
          { type: "text", margin: "2px", text: outfit.title, size: "xl", weight: "bold", color: CARD_COLOR.onImage },
        ],
        action: { type: "uri", label: "看大圖", uri: imageUrl },
        paddingAll: "16px",
        paddingTop: "60px",
      }),
      body: { type: "box", layout: "vertical", paddingAll: "16px", paddingTop: "8px", contents: rows },
      styles: { body: { backgroundColor: CARD_COLOR.surface } },
    },
  }, [
    messageChip("再配一套", "再幫我配一套"),
    messageChip("找類似的", "有沒有類似剛剛那套的其他穿搭"),
    cameraRollChip("試我自己的衣服"),
  ]);
}
