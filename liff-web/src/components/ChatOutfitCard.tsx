import type { CatalogItem } from "../api/catalog";
import { useWardrobeImage } from "../hooks/useWardrobeImage";
import { tryonGarment } from "../lib/garment";
import { collageOrder, outfitPurchase, purchaseCountText } from "../lib/outfit";
import { priceText } from "../lib/price";
import type { ResolvedItem, ResolvedOutfit } from "../state/chat";
import type { ChatTryonProps } from "./ChatItemCard";
import { FadeImage } from "./FadeImage";
import { SparkleIcon } from "./icons";

function WardrobeCell({ imagePath, labelled }: { imagePath: string; labelled: boolean }) {
  const src = useWardrobeImage(imagePath);
  return (
    <div className="look__cell">
      {src && <FadeImage className="look__img" src={src} alt="" loading="lazy" />}
      {labelled && <span className="ctag">衣櫃</span>}
    </div>
  );
}

/**
 * The photos carry no prices: the footer totals what is left to buy, and only
 * an owned piece is marked, so an unmarked cell reads as one to buy. A look
 * made only of owned pieces needs no marks: the footer already says so.
 */
function Cell({ piece, labelled, onOpen }: { piece: ResolvedItem; labelled: boolean; onOpen(item: CatalogItem): void }) {
  if (piece.kind === "wardrobe") return <WardrobeCell imagePath={piece.imagePath} labelled={labelled} />;
  const { item } = piece;
  return (
    <button type="button" className="look__cell" aria-label={item.name} onClick={() => onOpen(item)}>
      <FadeImage className="look__img" src={item.imageUrls[0]} alt="" loading="lazy" />
    </button>
  );
}

function PurchaseLine({ pieces }: { pieces: ResolvedItem[] }) {
  const purchase = outfitPurchase(pieces);
  if (purchase === null) return <span className="look__sum look__sum--own">全部來自你的衣櫃</span>;
  return (
    <span className="look__sum">
      {purchaseCountText(purchase, pieces.length)}
      <b>{priceText(purchase.total)}</b>
    </span>
  );
}

export function ChatOutfitCard(
  { outfit, onOpen, onTryon, tryonDisabled }:
    { outfit: ResolvedOutfit; onOpen(item: CatalogItem): void } & ChatTryonProps,
) {
  const labelled = outfit.pieces.some((piece) => piece.kind === "product");
  return (
    <div className="look">
      <div className={`look__collage look__collage--${outfit.pieces.length}`}>
        {collageOrder(outfit.pieces).map((piece, i) => (
          <Cell key={i} piece={piece} labelled={labelled} onOpen={onOpen} />
        ))}
      </div>
      <div className="look__over">
        <span className="look__title">{outfit.title}</span>
        {outfit.reason && <span className="look__reason">{outfit.reason}</span>}
        <div className="look__foot">
          <PurchaseLine pieces={outfit.pieces} />
          <button
            type="button"
            className="look__try"
            aria-label={`試穿整套「${outfit.title}」`}
            disabled={tryonDisabled}
            onClick={() => onTryon(outfit.pieces.map(tryonGarment), outfit.title)}
          >
            <SparkleIcon />
            試穿整套
          </button>
        </div>
      </div>
    </div>
  );
}
