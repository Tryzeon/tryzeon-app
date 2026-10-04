import type { PresetAvatar } from "../lib/presetAvatars";
import { MODEL_CHOICE_HINT, ModelChoicePicker, OwnPhotoTip } from "./ModelChoicePicker";
import { Overlay } from "./Overlay";

interface Props {
  presets: readonly PresetAvatar[];
  onPreset(preset: PresetAvatar): void;
  onUpload(file: File): void;
  onClose(): void;
}

export function ModelChoiceSheet({ presets, onPreset, onUpload, onClose }: Props) {
  return (
    <Overlay>
      <div className="sheet" role="dialog" aria-modal="true" aria-label="選擇試穿模特">
        <div className="sheet__backdrop" onClick={onClose} />
        <div className="sheet__panel sheet__panel--menu">
          <div className="sheet__body">
            <h2 className="sheet__name">選擇試穿模特</h2>
            <p className="sheet__hint">{MODEL_CHOICE_HINT}</p>
            <ModelChoicePicker
              presets={presets}
              disabled={false}
              onPreset={(preset) => {
                onClose();
                onPreset(preset);
              }}
              onUpload={(file) => {
                onClose();
                onUpload(file);
              }}
            />
            <OwnPhotoTip />
          </div>
        </div>
      </div>
    </Overlay>
  );
}
