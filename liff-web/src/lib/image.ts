export const JPEG_MIME = "image/jpeg";
export const JPEG_EXTENSION = "jpg";

export const UPLOAD_MAX_DIM = 2048;

export interface PixelRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export function downscaleDimensions(
  width: number,
  height: number,
  max: number,
): { width: number; height: number } {
  const longest = Math.max(width, height);
  if (longest <= max) return { width, height };
  const scale = max / longest;
  return { width: Math.round(width * scale), height: Math.round(height * scale) };
}

declare const jpegBrand: unique symbol;
export type JpegBlob = Blob & { readonly [jpegBrand]: true };

export async function cropToJpeg(
  imageUrl: string,
  area: PixelRect,
  maxDim = UPLOAD_MAX_DIM,
): Promise<JpegBlob> {
  return renderJpeg(await loadImage(imageUrl), area, maxDim);
}

function loadImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("failed to load image"));
    img.src = url;
  });
}

function renderJpeg(
  img: HTMLImageElement,
  area: PixelRect = { x: 0, y: 0, width: img.width, height: img.height },
  maxDim: number,
): Promise<JpegBlob> {
  const { width, height } = downscaleDimensions(area.width, area.height, maxDim);
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) return Promise.reject(new Error("canvas 2d context unavailable"));
  ctx.drawImage(img, area.x, area.y, area.width, area.height, 0, 0, width, height);
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (blob) resolve(blob as JpegBlob);
        else reject(new Error("canvas produced no blob"));
      },
      JPEG_MIME,
      0.9,
    );
  });
}

/**
 * Without the `data:` prefix — the edge function's `{ base64 }` expects raw
 * data, and sending the prefix along hands the decoder garbage bytes.
 */
function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      const comma = result.indexOf(",");
      resolve(comma === -1 ? result : result.slice(comma + 1));
    };
    reader.onerror = () => reject(reader.error ?? new Error("failed to read blob"));
    reader.readAsDataURL(blob);
  });
}

export async function downscaleToBase64(file: File, maxDim = UPLOAD_MAX_DIM): Promise<string> {
  const url = URL.createObjectURL(file);
  try {
    return blobToBase64(await renderJpeg(await loadImage(url), undefined, maxDim));
  } finally {
    URL.revokeObjectURL(url);
  }
}
