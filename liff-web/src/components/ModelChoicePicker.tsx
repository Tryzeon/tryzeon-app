import type { PresetAvatar } from "../lib/presetAvatars";
import { CameraPlusIcon } from "./icons";

export const MODEL_CHOICE_HINT = "先用預設模特試穿，或上傳自己的全身照";

export function OwnPhotoTip() {
  return (
    <div className="tipcard">
      <span className="tipcard__icon" aria-hidden="true">💡</span>
      <p className="tipcard__text">
        上傳自己的照片時，建議用短袖短褲的正面全身照，雙手自然下垂、手上不要拿手機等物品。
      </p>
    </div>
  );
}

interface Props {
  presets: readonly PresetAvatar[];
  disabled: boolean;
  onPreset(preset: PresetAvatar): void;
  onUpload(file: File): void;
}

export function ModelChoicePicker({ presets, disabled, onPreset, onUpload }: Props) {
  return (
    <div className="models">
      {presets.map((preset) => (
        <button
          key={preset.id}
          type="button"
          className="models__tile"
          disabled={disabled}
          onClick={() => onPreset(preset)}
        >
          <span className="models__frame">
            <img className="models__img" src={preset.url} alt={preset.label} />
          </span>
          <span className="models__title">{preset.label}</span>
          <span className="models__caption">立即開始試穿</span>
        </button>
      ))}

      <label className={`models__tile${disabled ? " is-disabled" : ""}`}>
        <span className="models__frame models__frame--upload">
          <CameraPlusIcon />
        </span>
        <span className="models__title">上傳全身照</span>
        <span className="models__caption">穿在自己身上</span>
        {/* Cleared after each pick, otherwise choosing the same photo twice in
            a row never fires onChange again. */}
        <input
          type="file"
          accept="image/*"
          hidden
          disabled={disabled}
          onChange={(e) => {
            const file = e.target.files?.[0];
            e.target.value = "";
            if (file) onUpload(file);
          }}
        />
      </label>
    </div>
  );
}
