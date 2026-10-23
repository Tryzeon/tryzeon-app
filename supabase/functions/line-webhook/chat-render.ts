/**
 * LINE has no equivalent of the core's ordered block list — it has messages, and
 * a bubble carousel is one message. So each `picks` row and each `outfits` row
 * becomes its own carousel and each run of text one message, preserving the ordering the model
 * meant for as long as it fits in a single send.
 */
import type {
  AnswerBlock,
  AnswerItems,
  OutfitRef,
  PickRef,
} from "../_shared/chat/index.ts";
import { type LineProduct, productItemBubble } from "./product-card.ts";
import { type LineWardrobeItem, wardrobeItemBubble } from "./wardrobe-card.ts";
import {
  type LineOutfit,
  outfitBubble,
  resolveOutfitPieces,
} from "./outfit-card.ts";
import { chatErrorMessage } from "./messages.ts";
import { dressLast, messageChip } from "./quick-reply.ts";

const MAX_LINE_MESSAGES = 5;
/** LINE's carousel cap; a search returns at most 10, so this is slack. */
const MAX_BUBBLES = 12;
const MAX_TEXT_CHARS = 5000;

/** A union rather than two section kinds: the two sit side by side in one carousel. */
type LineCard =
  | { kind: "product"; item: LineProduct; highlight?: string }
  | { kind: "wardrobe"; item: LineWardrobeItem; highlight?: string };

type Section =
  | { kind: "text"; lines: string[] }
  | { kind: "picks"; picks: LineCard[] }
  | { kind: "outfits"; outfits: LineOutfit[] };

function pickCards(picks: PickRef[], items: AnswerItems): LineCard[] {
  const cards: LineCard[] = [];
  for (const { type, id, highlight } of picks) {
    const tag = highlight ? { highlight } : {};
    if (type === "product") {
      const item = items.products[id];
      if (item) {
        cards.push({ kind: "product", item: item as LineProduct, ...tag });
      }
    } else {
      const item = items.wardrobe[id];
      if (item) {
        cards.push({
          kind: "wardrobe",
          item: item as LineWardrobeItem,
          ...tag,
        });
      }
    }
  }
  return cards;
}

function rowOutfits(outfits: OutfitRef[], items: AnswerItems): LineOutfit[] {
  const looks: LineOutfit[] = [];
  for (const look of outfits) {
    const pieces = resolveOutfitPieces(look.pieces, {
      product: (id) => items.products[id] as LineProduct | undefined,
      wardrobe: (id) => items.wardrobe[id] as LineWardrobeItem | undefined,
    });
    if (pieces) {
      looks.push({
        title: look.title,
        ...(look.reason ? { reason: look.reason } : {}),
        pieces,
      });
    }
  }
  return looks;
}

function toSections(blocks: AnswerBlock[], items: AnswerItems): Section[] {
  const sections: Section[] = [];
  for (const block of blocks) {
    if (block.type === "text") {
      const last = sections.at(-1);
      if (last?.kind === "text") last.lines.push(block.text);
      else sections.push({ kind: "text", lines: [block.text] });
    } else if (block.type === "picks") {
      const picks = pickCards(block.picks, items);
      if (picks.length > 0) sections.push({ kind: "picks", picks });
    } else {
      const outfits = rowOutfits(block.outfits, items);
      if (outfits.length > 0) sections.push({ kind: "outfits", outfits });
    }
  }
  return sections;
}

function textMessage(lines: string[]): object {
  return { type: "text", text: lines.join("\n").slice(0, MAX_TEXT_CHARS) };
}

const bubble = (card: LineCard, liffUrl: string): object =>
  card.kind === "product"
    ? productItemBubble(card.item, card.highlight, liffUrl)
    : wardrobeItemBubble(card.item, card.highlight);

/**
 * What a carousel is called when it cannot be shown — a notification, or a
 * client that will not render Flex. Named for what is in it, because "件商品"
 * is wrong for clothes the sender already owns.
 */
function carouselAltText(items: LineCard[]): string {
  const hasProduct = items.some((c) => c.kind === "product");
  const hasWardrobe = items.some((c) => c.kind === "wardrobe");

  if (hasWardrobe && !hasProduct) return `你衣櫃裡的 ${items.length} 件`;
  if (hasProduct && !hasWardrobe) return `為你找到 ${items.length} 件商品`;
  return `為你找到 ${items.length} 件`;
}

function carouselMessage(items: LineCard[], liffUrl: string): object {
  return {
    type: "flex",
    altText: carouselAltText(items),
    contents: {
      type: "carousel",
      contents: items.map((card) => bubble(card, liffUrl)),
    },
  };
}

function outfitsMessage(outfits: LineOutfit[], liffUrl: string): object {
  return {
    type: "flex",
    altText: `為你搭了 ${outfits.length} 套穿搭`,
    contents: {
      type: "carousel",
      contents: outfits.map((outfit) => outfitBubble(outfit, liffUrl)),
    },
  };
}

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

function sectionMessages(section: Section, liffUrl: string): object[] {
  switch (section.kind) {
    case "text":
      return [textMessage(section.lines)];
    case "picks":
      return chunk(section.picks, MAX_BUBBLES).map((cards) =>
        carouselMessage(cards, liffUrl)
      );
    case "outfits":
      return chunk(section.outfits, MAX_BUBBLES).map((looks) =>
        outfitsMessage(looks, liffUrl)
      );
  }
}

/**
 * All the prose, then every row in order — each still its own carousel, so a
 * fold never merges two rows into one carousel. Collapsed to
 * sections rather than straight to messages, so `sectionMessages` stays the one
 * route to a message and the chunk size, the altText and the character cap
 * cannot drift.
 */
function foldSections(sections: Section[]): Section[] {
  const lines = sections.flatMap((s) => s.kind === "text" ? s.lines : []);
  const rows = sections.filter((s) => s.kind !== "text");
  return lines.length > 0 ? [{ kind: "text", lines }, ...rows] : rows;
}

/**
 * When the interleaving fits it is kept; when it does not, the prose folds into
 * one message ahead of the rows. Only the fold can drop anything, and only once
 * the rows alone outrun `MAX_LINE_MESSAGES`.
 *
 * The chips are attached last, after any fold and its slice: a message the slice
 * drops must not take its chip's would-be home down with it.
 */
export function renderAnswer(
  blocks: AnswerBlock[],
  items: AnswerItems,
  liffUrl: string,
  suggestions: string[],
): object[] {
  const sections = toSections(blocks, items);

  // An answer of only unhydrated items leaves nothing renderable, and LINE
  // rejects an empty send outright.
  if (sections.length === 0) return [chatErrorMessage("unknown")];

  const detailed = sections.flatMap((s) => sectionMessages(s, liffUrl));
  const messages = detailed.length <= MAX_LINE_MESSAGES
    ? detailed
    : foldSections(sections).flatMap((s) => sectionMessages(s, liffUrl)).slice(
      0,
      MAX_LINE_MESSAGES,
    );

  return dressLast(messages, suggestions.map((s) => messageChip(s, s)));
}
