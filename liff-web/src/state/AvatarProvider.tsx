import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { avatarUrl, setPresetAvatar, uploadAvatar } from "../api/avatar";
import type { StoredAvatar } from "../api/avatar-wire";
import { type Gender, type PresetAvatar, presetsForGender } from "../lib/presetAvatars";
import {
  type AvatarPreview,
  type AvatarStatus,
  avatarStatus,
  settleOnSave,
  settleOnSigned,
  shownUrl,
  type SignedAvatar,
} from "./avatar";

interface AvatarValue {
  avatar: StoredAvatar | null;
  /** While a replacement is in flight, the model being saved — it shows
   * before it is saved. */
  url: string | null;
  /** Not the same as [url] being ready — still true while the signature is
   * in flight. */
  hasAvatar: boolean;
  status: AvatarStatus;
  busy: boolean;
  presets: readonly PresetAvatar[];
  replace(file: File): Promise<boolean>;
  applyPreset(preset: PresetAvatar): Promise<boolean>;
}

const AvatarContext = createContext<AvatarValue | null>(null);

export function AvatarProvider(
  { initialAvatar, gender, children }: {
    initialAvatar: StoredAvatar | null;
    gender: Gender | null;
    children: ReactNode;
  },
) {
  const [avatar, setAvatar] = useState(initialAvatar);
  const [signed, setSigned] = useState<SignedAvatar | null>(null);
  const [preview, setPreview] = useState<AvatarPreview | null>(null);
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);

  const objectUrl = preview?.kind === "upload" ? preview.objectUrl : null;
  useEffect(() => {
    if (objectUrl === null) return;
    return () => URL.revokeObjectURL(objectUrl);
  }, [objectUrl]);

  const uploadedPath = avatar?.kind === "uploaded" ? avatar.path : null;
  useEffect(() => {
    if (uploadedPath === null) return;

    let live = true;
    const settle = (url: string | null) => {
      if (!live) return;
      setSigned({ path: uploadedPath, url });
      setPreview((p) => settleOnSigned(p, uploadedPath));
    };
    avatarUrl(uploadedPath).then(settle, () => settle(null));
    return () => {
      live = false;
    };
  }, [uploadedPath]);

  // Exclusive until the write settles: a second pick mid-save would race the
  // first one for the profile's avatar columns.
  const save = useCallback(
    async (
      startPreview: () => AvatarPreview,
      write: () => Promise<StoredAvatar>,
    ): Promise<boolean> => {
      if (busyRef.current) return false;
      busyRef.current = true;
      setBusy(true);
      setPreview(startPreview());
      try {
        const saved = await write();
        setAvatar(saved);
        setPreview((p) => settleOnSave(p, saved));
        return true;
      } catch (err) {
        console.error("[avatar] replace failed:", err);
        setPreview(null);
        return false;
      } finally {
        busyRef.current = false;
        setBusy(false);
      }
    },
    [],
  );

  const replace = useCallback(
    (file: File) =>
      save(
        () => ({ kind: "upload", objectUrl: URL.createObjectURL(file), savedAs: null }),
        () => uploadAvatar(file),
      ),
    [save],
  );
  const applyPreset = useCallback(
    (preset: PresetAvatar) =>
      save(
        () => ({ kind: "preset", id: preset.id }),
        () => setPresetAvatar(preset.id),
      ),
    [save],
  );

  const presets = useMemo(() => presetsForGender(gender), [gender]);

  const value = useMemo(
    () => ({
      avatar,
      url: shownUrl(preview, avatar, signed),
      hasAvatar: avatar !== null,
      status: avatarStatus(avatar, signed),
      busy,
      presets,
      replace,
      applyPreset,
    }),
    [avatar, preview, signed, busy, presets, replace, applyPreset],
  );

  return <AvatarContext.Provider value={value}>{children}</AvatarContext.Provider>;
}

export function useAvatar(): AvatarValue {
  const value = useContext(AvatarContext);
  if (value === null) throw new Error("useAvatar outside AvatarProvider");
  return value;
}
