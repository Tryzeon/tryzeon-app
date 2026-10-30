import type { ReactNode } from "react";
import type { CatalogItem } from "../api/catalog";
import type { CatalogColor } from "../api/catalog-row";
import type { Garment } from "../api/tryon";
import { useWardrobeImage } from "../hooks/useWardrobeImage";
import { tryonGarment, wardrobeCardName } from "../lib/garment";
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

interface CardFrameProps {
  image: ReactNode;
  highlight?: string;
  source?: string;
  name: ReactNode;
  value: ReactNode;
  tryon: ReactNode;
  link?: boolean;
}

function CardFrame({ image, highlight, source, name, value, tryon, link }: CardFrameProps) {
  return (
    <div className={link ? "ccard ccard--link" : "ccard"}>
      {image}
      {highlight && <span className="ctag">{highlight}</span>}
      <div className="ccard__info">
        {source && <span className="ccard__source">{source}</span>}
        {name}
        <div className="ccard__row">
          {value}
          {tryon}
        </div>
      </div>
    </div>
  );
}

function WardrobeItemCard(
  { item, highlight, onTryon, tryonDisabled }: { item: ResolvedWardrobe; highlight?: string } & ChatTryonProps,
) {
  const src = useWardrobeImage(item.imagePath);
  const name = wardrobeCardName(item.garmentType, item.tags);
  return (
    <CardFrame
      image={src && <FadeImage className="ccard__img" src={src} alt="" loading="lazy" />}
      highlight={highlight}
      source="衣櫃"
      name={<span className="ccard__name">{name}</span>}
      value={<span className="ccard__price ccard__price--owned">已擁有</span>}
      tryon={<TryonChip name={name} disabled={tryonDisabled} onClick={() => onTryon([tryonGarment(item)], name)} />}
    />
  );
}

/**
 * The name is the card's one link, stretched over the whole card, so the card
 * stays tappable anywhere without nesting the try-on button inside another.
 */
export function ChatItemCard(
  { item, highlight, onOpen, onTryon, tryonDisabled }:
    { item: ResolvedItem; highlight?: string; onOpen(item: CatalogItem, color: CatalogColor | null): void } & ChatTryonProps,
) {
  if (item.kind === "wardrobe") {
    return <WardrobeItemCard item={item} highlight={highlight} onTryon={onTryon} tryonDisabled={tryonDisabled} />;
  }
  const product = item.item;
  const cover = item.color?.imageUrls[0];
  return (
    <CardFrame
      link
      image={cover && <FadeImage className="ccard__img" src={cover} alt="" loading="lazy" />}
      highlight={highlight}
      source={product.storeName ?? undefined}
      name={
        <button type="button" className="ccard__open" onClick={() => onOpen(product, item.color)}>
          <span className="ccard__name">{product.name}</span>
        </button>
      }
      value={<span className="ccard__price">{priceText(product.price)}</span>}
      tryon={
        <TryonChip
          name={product.name}
          disabled={tryonDisabled}
          onClick={() => onTryon([tryonGarment(item)], product.name)}
        />
      }
    />
  );
}
