import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Header } from "../components/Header";
import {
  MODEL_CHOICE_HINT,
  ModelChoicePicker,
  OwnPhotoTip,
} from "../components/ModelChoicePicker";
import { useAvatar } from "../state/AvatarProvider";

type Phase = "ready" | "saving" | "done" | "error";

export function Onboard() {
  const navigate = useNavigate();
  const avatar = useAvatar();
  const [phase, setPhase] = useState<Phase>("ready");

  async function save(apply: () => Promise<boolean>) {
    setPhase("saving");
    setPhase(await apply() ? "done" : "error");
  }

  const choosing = phase === "ready" || phase === "error";

  return (
    <div className="app">
      <Header />
      <main className="main">
        <p className="eyebrow">選擇你的試穿模特</p>

        {choosing
          ? (
            <>
              <p className="cta__hint">{MODEL_CHOICE_HINT}。照片只用於試穿。</p>
              {phase === "error" && (
                <div className="errorcard">儲存失敗，請稍後再試或換一張清楚的全身照。</div>
              )}
              <div className="onboard__picker">
                <ModelChoicePicker
                  presets={avatar.presets}
                  disabled={avatar.busy}
                  onPreset={(preset) => save(() => avatar.applyPreset(preset))}
                  onUpload={(file) => save(() => avatar.replace(file))}
                />
              </div>
              <OwnPhotoTip />
            </>
          )
          : (
            <figure className="preview">
              <div className="frame">
                {avatar.url !== null && (
                  <img className="frame__img" src={avatar.url} alt="你選擇的試穿模特" />
                )}
                {phase === "saving" && (
                  <div className="frame__veil">
                    <span className="spinner" aria-hidden="true" />
                  </div>
                )}
                {phase === "done" && (
                  <span className="frame__badge" aria-hidden="true">
                    ✓
                  </span>
                )}
              </div>
              {phase === "done" && (
                <figcaption className="frame__caption">試穿模特已設定</figcaption>
              )}
            </figure>
          )}
      </main>

      {phase === "done" && (
        <div className="actionbar">
          <button type="button" className="cta" onClick={() => navigate("/")}>
            前往試衣間
          </button>
          <span className="cta__hint">回聊天室再傳一次衣服圖，就會自動幫你試穿。</span>
        </div>
      )}
    </div>
  );
}
