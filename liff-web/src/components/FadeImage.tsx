import { useEffect, useRef, useState, type ImgHTMLAttributes } from "react";

interface Props extends ImgHTMLAttributes<HTMLImageElement> {
  src: string;
  onLoaded?(): void;
}

/** An image the browser already had fires `load` before React attaches the
 * handler, so `complete` is checked as well once the element is in the DOM. */
export function FadeImage({ src, className, onLoaded, ...rest }: Props) {
  const ref = useRef<HTMLImageElement>(null);
  const [loaded, setLoaded] = useState(false);

  function reveal() {
    setLoaded(true);
    onLoaded?.();
  }

  useEffect(() => {
    if (ref.current?.complete) reveal();
    else setLoaded(false);
  }, [src]);

  return (
    <img
      ref={ref}
      src={src}
      className={`${className ?? ""} fade${loaded ? " is-loaded" : ""}`}
      onLoad={reveal}
      {...rest}
    />
  );
}
