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
import { avatarUrl, setAvatar } from "../api/avatar";
import {
  type Gender,
  type PresetAvatar,
  presetAvatarFile,
  presetsForGender,
} from "../lib/presetAvatars";

interface AvatarValue {
  /** While a replacement is in flight, the photo being uploaded — it shows
   * before it is saved. */
  url: string | null;
  /** Not the same as [url] being ready — still true while the signature is
   * in flight. */
  hasAvatar: boolean;
  status: "loading" | "ready" | "error";
  busy: boolean;
  presets: readonly PresetAvatar[];
  replace(file: File): Promise<boolean>;
  applyPreset(preset: PresetAvatar): Promise<boolean>;
}

/** [forPath] is the path this photo was saved under, null until the upload
 * lands; only that path's signature may retire it, so a slower signature for
 * an earlier save cannot clear the preview of a later one. */
interface Pending {
  url: string;
  forPath: string | null;
}

const AvatarContext = createContext<AvatarValue | null>(null);

export function AvatarProvider(
  { initialPath, gender, children }: {
    initialPath: string | null;
    gender: Gender | null;
    children: ReactNode;
  },
) {
  const [path, setPath] = useState(initialPath);
  const [url, setUrl] = useState<string | null>(null);
  const [pending, setPending] = useState<Pending | null>(null);
  const pendingUrl = pending?.url ?? null;
  const [status, setStatus] = useState<AvatarValue["status"]>(
    initialPath === null ? "ready" : "loading",
  );
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);

  useEffect(() => {
    if (pendingUrl === null) return;
    return () => URL.revokeObjectURL(pendingUrl);
  }, [pendingUrl]);

  useEffect(() => {
    if (path === null) {
      setUrl(null);
      setStatus("ready");
      return;
    }

    let live = true;
    const settle = (p: Pending | null) => (p?.forPath === path ? null : p);
    // The previous photo's URL must not outlive its path: if this signature
    // fails, showing it would pass the old photo off as the saved one.
    setUrl(null);
    setStatus("loading");
    avatarUrl(path).then(
      (signed) => {
        if (!live) return;
        setUrl(signed);
        setPending(settle);
        setStatus("ready");
      },
      () => {
        if (!live) return;
        setPending(settle);
        setStatus("error");
      },
    );
    return () => {
      live = false;
    };
  }, [path]);

  // Exclusive until the upload settles: a second pick mid-upload would race
  // the first one for the profile's avatar_path.
  const save = useCallback(async (prepare: () => Promise<File>): Promise<boolean> => {
    if (busyRef.current) return false;
    busyRef.current = true;
    setBusy(true);
    try {
      const file = await prepare();
      setPending({ url: URL.createObjectURL(file), forPath: null });
      const saved = await setAvatar(file);
      setPending((p) => p && { ...p, forPath: saved });
      setPath(saved);
      return true;
    } catch (err) {
      console.error("[avatar] replace failed:", err);
      setPending(null);
      return false;
    } finally {
      busyRef.current = false;
      setBusy(false);
    }
  }, []);

  const replace = useCallback((file: File) => save(async () => file), [save]);
  const applyPreset = useCallback(
    (preset: PresetAvatar) => save(() => presetAvatarFile(preset)),
    [save],
  );

  const presets = useMemo(() => presetsForGender(gender), [gender]);

  const value = useMemo(
    () => ({
      url: pendingUrl ?? url,
      hasAvatar: path !== null,
      status,
      busy,
      presets,
      replace,
      applyPreset,
    }),
    [pendingUrl, url, path, status, busy, presets, replace, applyPreset],
  );

  return <AvatarContext.Provider value={value}>{children}</AvatarContext.Provider>;
}

export function useAvatar(): AvatarValue {
  const value = useContext(AvatarContext);
  if (value === null) throw new Error("useAvatar outside AvatarProvider");
  return value;
}
