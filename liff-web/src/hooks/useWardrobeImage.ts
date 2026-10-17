import { useEffect, useState } from "react";
import { wardrobeImageUrl } from "../api/wardrobe";

export function useWardrobeImage(imagePath: string): string | null {
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

  return src;
}
