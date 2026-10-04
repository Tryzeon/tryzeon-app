import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { nextLoadingVideo } from "../lib/loadingVideos";
import { nearestPage } from "../lib/pager";
import type { GalleryEntry } from "../state/gallery";
import { FadeImage } from "./FadeImage";

/** Tolerance for deciding we are already on a page; snapping often leaves a
 * sub-pixel remainder. */
const TOLERANCE_PX = 2;

/** How long the loading clip stays underneath a result while it fades in.
 * A timer rather than transitionend, which never fires under reduced motion. */
const REVEAL_MS = 500;

interface Props {
  entries: GalleryEntry[];
  avatarPage: ReactNode;
  page: number;
  onPageChange(page: number): void;
  onResultTap(imageUrl: string): void;
}

/**
 * CSS scroll-snap rather than hand-rolled gesture math: native scrolling's
 * momentum and rubber-banding already coexist with LINE's webview edge
 * gestures, and handling touch events ourselves would only break them.
 */
export function TryonPager(
  { entries, avatarPage, page, onPageChange, onResultTap }: Props,
) {
  const trackRef = useRef<HTMLDivElement>(null);

  // Together these two refs keep state → scroll position and scroll position →
  // state apart. The page is reported live as the finger crosses each midpoint,
  // so the caption follows the swipe instead of waiting for the snap to end;
  // that only works because the effect below recognises pages it was told
  // about by the scroll listener and leaves the scroll position alone for
  // them. Without `target`, every page a smooth scroll passes through would be
  // reported as a page change, and a multi-page jump (tapping try-on again
  // with two try-ons already there) would stall on the first one.
  const reported = useRef<number | null>(null);
  const target = useRef<number | null>(null);

  // State → scroll position: bring the new page into view when a try-on starts.
  useEffect(() => {
    if (page === reported.current) return;
    const track = trackRef.current;
    if (track === null || track.clientWidth === 0) return;
    const left = page * track.clientWidth;
    if (Math.abs(track.scrollLeft - left) < TOLERANCE_PX) {
      target.current = null;
      return;
    }
    target.current = left;
    track.scrollTo({ left, behavior: "smooth" });
  }, [page]);

  function handleScroll() {
    const track = trackRef.current;
    if (track === null || track.clientWidth === 0) return;

    // Pages a smooth scroll merely passes through are not the user's choice, so
    // report nothing until it arrives.
    if (target.current !== null) {
      if (Math.abs(track.scrollLeft - target.current) > TOLERANCE_PX) return;
      target.current = null;
    }

    const next = nearestPage(track.scrollLeft, track.clientWidth, track.childElementCount);
    if (next === reported.current) return;
    reported.current = next;
    onPageChange(next);
  }

  // Any touch invalidates the programmatic scroll target: once the user takes
  // over, that target is never reached, and keeping it would stop handleScroll
  // from ever reporting a page again.
  function releaseTarget() {
    target.current = null;
  }

  return (
    <div
      className="pager"
      ref={trackRef}
      onScroll={handleScroll}
      onPointerDown={releaseTarget}
      onTouchStart={releaseTarget}
    >
      {avatarPage}

      {entries.map((entry) => (
        <TryonPage key={entry.id} entry={entry} onResultTap={onResultTap} />
      ))}
    </div>
  );
}

type Reveal = "waiting" | "fading" | "done";

/** One page for the whole life of a try-on: the loading clip keeps playing
 * under the result until the photo has faded in, so the switch is a crossfade
 * rather than a cut to grey. */
function TryonPage(
  { entry, onResultTap }: { entry: GalleryEntry; onResultTap(imageUrl: string): void },
) {
  const clip = useMemo(nextLoadingVideo, []);
  const [reveal, setReveal] = useState<Reveal>("waiting");

  useEffect(() => {
    if (reveal !== "fading") return;
    const timer = setTimeout(() => setReveal("done"), REVEAL_MS);
    return () => clearTimeout(timer);
  }, [reveal]);

  const finished = entry.kind === "finished";

  return (
    <div
      className="page"
      onClick={finished ? () => onResultTap(entry.imageUrl) : undefined}
    >
      {reveal !== "done" && (
        <video
          className={`page__img page__clip${reveal === "fading" ? " is-out" : ""}`}
          src={clip}
          muted
          loop
          playsInline
          autoPlay
          preload="auto"
        />
      )}
      {finished && (
        <FadeImage
          className="page__img page__result"
          src={entry.imageUrl}
          alt="試穿結果"
          onLoaded={() => setReveal((r) => (r === "waiting" ? "fading" : r))}
        />
      )}
    </div>
  );
}
