import type { CatalogItem } from "../api/catalog";
import type { Garment } from "../api/tryon";
import { useWardrobeImage } from "../hooks/useWardrobeImage";
import { garmentTypeLabel, tryonGarment } from "../lib/garment";
import { priceText } from "../lib/price";
import type { ResolvedItem } from "../state/chat";
import { FadeImage } from "./FadeImage";
import { SparkleIcon } from "./icons";

type ResolvedWardrobe = Extract<ResolvedItem, { kind: "wardrobe" }>;

export interface ChatTryonProps {
  onTryon(garments: Garment[], caption: string): void;
  tryonDisabled: boolean;
}

function TryonChip({ name, onClick, disabled }: { name: string; onClick(): void; disabled: boolean }) {
  return (
    <button
      type="button"
      className="ccard__try"
      aria-label={`試穿「${name}」`}
      disabled={disabled}
      onClick={onClick}
    >
      <SparkleIcon />
      試穿
    </button>
  );
}

function WardrobeItemCard(
  { item, highlight, onTryon, tryonDisabled }: { item: ResolvedWardrobe; highlight?: string } & ChatTryonProps,
) {
  const src = useWardrobeImage(item.imagePath);
  const name = garmentTypeLabel(item.garmentType);
  return (
    <div className="ccard">
      <div className="ccard__media">
        {src && <FadeImage className="ccard__img ccard__img--cutout" src={src} alt="" loading="lazy" />}
        {highlight && <span className="ctag">{highlight}</span>}
        <TryonChip name={name} disabled={tryonDisabled} onClick={() => onTryon([tryonGarment(item)], name)} />
      </div>
      <span className="ccard__source">你的衣櫃</span>
      <span className="ccard__name">{[name, ...item.tags.slice(0, 3)].join(" · ")}</span>
    </div>
  );
}

/**
 * The name is the card's one link, stretched over the whole card, so the card
 * stays tappable anywhere without nesting the try-on button inside another.
 */
export function ChatItemCard(
  { item, highlight, onOpen, onTryon, tryonDisabled }:
    { item: ResolvedItem; highlight?: string; onOpen(item: CatalogItem): void } & ChatTryonProps,
) {
  if (item.kind === "wardrobe") {
    return <WardrobeItemCard item={item} highlight={highlight} onTryon={onTryon} tryonDisabled={tryonDisabled} />;
  }
  const product = item.item;
  return (
    <div className="ccard ccard--link">
      <div className="ccard__media">
        <FadeImage className="ccard__img" src={product.imageUrls[0]} alt="" loading="lazy" />
        {highlight && <span className="ctag">{highlight}</span>}
        <TryonChip
          name={product.name}
          disabled={tryonDisabled}
          onClick={() => onTryon([tryonGarment(item)], product.name)}
        />
      </div>
      {product.storeName && <span className="ccard__source">{product.storeName}</span>}
      <button type="button" className="ccard__open" onClick={() => onOpen(product)}>
        <span className="ccard__name">{product.name}</span>
      </button>
      <span className="ccard__price">{priceText(product.price)}</span>
    </div>
  );
}
