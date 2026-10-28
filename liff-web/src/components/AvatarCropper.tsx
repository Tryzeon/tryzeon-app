import { useEffect, useRef, useState } from "react";
import Cropper, { type Area, type Point } from "react-easy-crop";
import { cropToJpeg, type JpegBlob } from "../lib/image";
import { Overlay } from "./Overlay";

const AVATAR_ASPECT = 9 / 16;

type Status = "loading" | "ready" | "saving" | "encodeFailed" | "unreadable";

const FRAMING_HINT = "拖曳或雙指縮放，讓頭到腳都在框內";
const HINTS: Record<Status, string> = {
  loading: FRAMING_HINT,
  ready: FRAMING_HINT,
  saving: FRAMING_HINT,
  encodeFailed: "照片處理失敗，請再試一次。",
  unreadable: "這張照片無法讀取，換一張再試。",
};

interface Props {
  file: File;
  onCancel(): void;
  onCrop(jpeg: JpegBlob): void;
}

export function AvatarCropper({ file, onCancel, onCrop }: Props) {
  const [src, setSrc] = useState<string | null>(null);
  const [crop, setCrop] = useState<Point>({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [area, setArea] = useState<Area | null>(null);
  const [status, setStatus] = useState<Status>("loading");
  const mounted = useRef(true);

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  useEffect(() => {
    const url = URL.createObjectURL(file);
    setSrc(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  async function confirm() {
    if (src === null || area === null) return;
    if (status !== "ready" && status !== "encodeFailed") return;
    setStatus("saving");
    try {
      const jpeg = await cropToJpeg(src, area);
      if (mounted.current) onCrop(jpeg);
    } catch (err) {
      console.error("[avatar] crop failed:", err);
      if (mounted.current) setStatus("encodeFailed");
    }
  }

  const canConfirm = area !== null && (status === "ready" || status === "encodeFailed");
  const isError = status === "encodeFailed" || status === "unreadable";

  return (
    <Overlay>
      <div className="cropper" role="dialog" aria-modal="true" aria-label="框出全身">
        <p className="cropper__title">框出全身</p>
        <div className="cropper__stage">
          {src !== null && status !== "unreadable" && (
            <Cropper
              image={src}
              crop={crop}
              zoom={zoom}
              aspect={AVATAR_ASPECT}
              onCropChange={setCrop}
              onZoomChange={setZoom}
              onCropComplete={(_, pixels) => setArea(pixels)}
              onMediaLoaded={() => setStatus("ready")}
              mediaProps={{ onError: () => setStatus("unreadable") }}
            />
          )}
        </div>
        <p className={`cropper__hint${isError ? " is-error" : ""}`}>{HINTS[status]}</p>
        <div className="cropper__bar">
          <button
            type="button"
            className="cropper__cancel"
            disabled={status === "saving"}
            onClick={onCancel}
          >
            取消
          </button>
          <button type="button" className="cropper__ok" disabled={!canConfirm} onClick={confirm}>
            {status === "saving"
              ? <span className="spinner spinner--ink" aria-hidden="true" />
              : "使用這張照片"}
          </button>
        </div>
      </div>
    </Overlay>
  );
}
