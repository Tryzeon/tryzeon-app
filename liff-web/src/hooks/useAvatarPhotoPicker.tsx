import { useState } from "react";
import { AvatarCropper } from "../components/AvatarCropper";
import type { JpegBlob } from "../lib/image";

export function useAvatarPhotoPicker(onPick: (jpeg: JpegBlob) => void) {
  const [file, setFile] = useState<File | null>(null);

  const cropper = file !== null && (
    <AvatarCropper
      file={file}
      onCancel={() => setFile(null)}
      onCrop={(jpeg) => {
        setFile(null);
        onPick(jpeg);
      }}
    />
  );

  return { pick: setFile, cropper };
}
