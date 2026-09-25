import { useEffect, useState } from "react";
import { wardrobeImageUrl } from "../api/wardrobe";
import { FadeImage } from "./FadeImage";

export function WardrobeCard({ imagePath }: { imagePath: string }) {
  const [src, setSrc] = useState<string | null>(null);

  useEffect(() => {
    let live = true;
    wardrobeImageUrl(imagePath).then(
      (url) => {
        if (live) setSrc(url);
      },
      (err) => console.warn("[chat] wardrobe image signing failed:", err),
    );
    return () => {
      live = false;
    };
  }, [imagePath]);

  return (
    <div className="card">
      {src
        ? <FadeImage className="card__img" src={src} alt="" loading="lazy" />
        : <span className="card__img card__img--empty" />}
      <span className="card__meta">
        <span className="card__store">我的衣櫃</span>
      </span>
    </div>
  );
}
