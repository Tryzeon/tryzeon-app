import { useRef, useState } from "react";
import { ModelChoiceSheet } from "../components/ModelChoiceSheet";
import { selectedPresetId } from "../state/avatar";
import { useAvatar } from "../state/AvatarProvider";

/** A try-on needs a model first: without one, the model sheet opens and the
 * try-on that was asked for runs once a model is chosen. */
export function useModelGatedTryon() {
  const avatar = useAvatar();
  const queued = useRef<(() => Promise<void>) | null>(null);
  const [choosing, setChoosing] = useState(false);
  const [choiceFailed, setChoiceFailed] = useState(false);

  function start(tryon: () => Promise<void>) {
    if (avatar.busy) return;
    if (avatar.hasAvatar) {
      void tryon();
      return;
    }
    queued.current = tryon;
    setChoosing(true);
  }

  async function chooseThenTryon(choose: () => Promise<boolean>) {
    const tryon = queued.current;
    queued.current = null;
    setChoiceFailed(false);
    if (!await choose()) {
      setChoiceFailed(true);
      return;
    }
    await tryon?.();
  }

  const sheet = choosing && (
    <ModelChoiceSheet
      presets={avatar.presets}
      selected={selectedPresetId(avatar.avatar)}
      onPreset={(preset) => chooseThenTryon(() => avatar.applyPreset(preset))}
      onUpload={(file) => chooseThenTryon(() => avatar.replace(file))}
      onClose={() => setChoosing(false)}
    />
  );

  return { start, sheet, choiceFailed, busy: avatar.busy };
}
