import { useState } from "react";
import { nearestPage } from "../lib/pager";
import { FadeImage } from "./FadeImage";

/** Photos are narrower than the track and snap to its centre, so the offset
 * of a centred photo is measured from the track's midpoint, not its left edge. */
function centredIndex(track: HTMLElement, count: number): number {
  const first = track.children[0] as HTMLElement | undefined;
  const second = track.children[1] as HTMLElement | undefined;
  if (first === undefined) return 0;
  const step = second === undefined
    ? first.offsetWidth
    : second.offsetLeft - first.offsetLeft;
  const inset = (track.clientWidth - first.offsetWidth) / 2;
  return nearestPage(track.scrollLeft + inset, step, count);
}

export function ProductGallery({ imageUrls }: { imageUrls: string[] }) {
  const [index, setIndex] = useState(0);

  if (imageUrls.length === 0) {
    return (
      <div className="gallery">
        <div className="gallery__img gallery__img--empty">暫無照片</div>
      </div>
    );
  }

  return (
    <>
      <div
        className="gallery"
        onScroll={(e) => setIndex(centredIndex(e.currentTarget, imageUrls.length))}
      >
        {imageUrls.map((url) => (
          <FadeImage key={url} className="gallery__img" src={url} alt="" />
        ))}
      </div>
      {imageUrls.length > 1 && (
        <div className="gallery__dots dots dots--ink" aria-hidden="true">
          {imageUrls.map((url, i) => (
            <span key={url} className={`dots__dot${i === index ? " is-active" : ""}`} />
          ))}
        </div>
      )}
    </>
  );
}
