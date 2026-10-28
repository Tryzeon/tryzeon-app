import type { JpegBlob } from "../lib/image";
import type { PresetAvatar } from "../lib/presetAvatars";
import { useAvatar } from "../state/AvatarProvider";
import { FadeImage } from "./FadeImage";
import { MODEL_CHOICE_HINT, ModelChoicePicker } from "./ModelChoicePicker";

interface Props {
  onReplaceTap(): void;
  onPreset(preset: PresetAvatar): void;
  onUpload(jpeg: JpegBlob): void;
}

export function AvatarPage({ onReplaceTap, onPreset, onUpload }: Props) {
  const avatar = useAvatar();

  if (avatar.hasAvatar || avatar.url !== null) {
    return (
      <div className="page" onClick={onReplaceTap}>
        {avatar.url !== null && (
          <FadeImage className="page__img" src={avatar.url} alt="你的 model 照" />
        )}
        {(avatar.busy || avatar.status === "loading") && (
          <div className="page__veil">
            <span className="spinner" aria-hidden="true" />
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="page page--blank">
      <div className="page__choice">
        <p className="page__choicetitle">選擇你的試穿模特</p>
        <p className="page__choicehint">{MODEL_CHOICE_HINT}</p>
        <ModelChoicePicker
          presets={avatar.presets}
          selected={null}
          disabled={avatar.busy}
          onPreset={onPreset}
          onUpload={onUpload}
        />
      </div>
    </div>
  );
}
