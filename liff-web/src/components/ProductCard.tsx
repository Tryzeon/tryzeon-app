import type { CatalogItem } from "../api/catalog";
import { coverImageUrl } from "../api/catalog-row";
import { priceText } from "../lib/price";
import { FadeImage } from "./FadeImage";

export function ProductCard({ item, onOpen }: { item: CatalogItem; onOpen(): void }) {
  const cover = coverImageUrl(item);
  return (
    <button type="button" className="card" onClick={onOpen}>
      {cover
        ? <FadeImage className="card__img" src={cover} alt="" loading="lazy" />
        : <span className="card__img card__img--empty">暫無照片</span>}
      <span className="card__meta">
        <span className="card__name">{item.name}</span>
        {item.storeName && <span className="card__store">{item.storeName}</span>}
        <span className="card__price">{priceText(item.price)}</span>
      </span>
    </button>
  );
}
