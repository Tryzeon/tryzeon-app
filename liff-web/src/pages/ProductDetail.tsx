import { useEffect, useRef, useState, type ReactNode } from "react";
import { useLocation, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { fetchProduct, type CatalogItem } from "../api/catalog";
import { hasColorChoice, resolveColor } from "../api/catalog-row";
import { FadeImage } from "../components/FadeImage";
import { Header } from "../components/Header";
import { ChevronLeftIcon } from "../components/icons";
import { ProductGallery } from "../components/ProductGallery";
import { useModelGatedTryon } from "../hooks/useModelGatedTryon";
import { useTryonCoordinator } from "../hooks/useTryonCoordinator";
import { isExternalUrl, openExternal } from "../lib/liff";
import { priceText } from "../lib/price";

type Load =
  | { status: "loading" }
  | { status: "ready"; item: CatalogItem }
  | { status: "missing" }
  | { status: "error" };

/** This page is done the moment try-on is tapped: the coordinator moves the
 * user to home, and the result lands in that gallery. */
export function ProductDetail() {
  const { id } = useParams<{ id: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const colorParam = searchParams.get("color");
  const navigate = useNavigate();

  const location = useLocation();

  // Arriving from the catalog, the row travelled along with the navigation, so
  // render it straight away instead of flashing a skeleton. Only a direct URL
  // (a LINE message, a shared link) has none, and that is when we fetch.
  const seeded = seededItem(location.state);
  const [load, setLoad] = useState<Load>(
    seeded === null ? { status: "loading" } : { status: "ready", item: seeded },
  );
  const needsFetch = seeded === null;

  useEffect(() => {
    if (id === undefined || !needsFetch) return;

    let live = true;
    setLoad({ status: "loading" });
    fetchProduct(id).then(
      (item) => {
        if (!live) return;
        setLoad(item === null ? { status: "missing" } : { status: "ready", item });
      },
      () => {
        if (live) setLoad({ status: "error" });
      },
    );
    return () => {
      live = false;
    };
  }, [id, needsFetch]);

  // Decided by location.key — react-router only gives the key "default" to the
  // entry that was already there on arrival. Not history.length: LIFF reaches
  // this URL through a chain of redirects, so on a deep link it is already
  // greater than 1, and using it would send the user back to a redirect page,
  // straight out of this app. Read once on arrival: picking a colour replaces
  // the entry, and even a replace gets a fresh key.
  const [isEntry] = useState(location.key === "default");
  function goBack() {
    if (isEntry) navigate("/");
    else navigate(-1);
  }

  const back = (
    <button type="button" className="pdp__back" onClick={goBack} aria-label="返回">
      <ChevronLeftIcon />
    </button>
  );

  return (
    <div className="app pdp-app">
      <Header title={load.status === "ready" ? load.item.storeName : null} />

      {load.status === "ready"
        ? (
          <Detail
            item={load.item}
            colorId={colorParam}
            onSelectColor={(colorId) =>
              setSearchParams((prev) => {
                const next = new URLSearchParams(prev);
                next.set("color", colorId);
                return next;
              }, { replace: true, state: location.state })}
            back={back}
          />
        )
        : (
          <main className="main pdp">
            <div className="pdp__media">
              {back}
              <div
                className={`pdp__skgallery ${load.status === "loading" ? "sk" : "pdp__media--blank"}`}
              />
            </div>

            {load.status === "loading" && (
              <>
                <div className="sk pdp__skline pdp__skline--short" />
                <div className="sk pdp__skline" />
              </>
            )}

            {load.status === "missing" && (
              <p className="empty">找不到這件商品，它可能已經下架了。</p>
            )}

            {load.status === "error" && (
              <>
                <div className="errorcard">商品載入失敗，請稍後再試。</div>
                <button className="loadmore" onClick={() => navigate(0)}>重新載入</button>
              </>
            )}
          </main>
        )}
    </div>
  );
}

function Detail(
  { item, colorId, onSelectColor, back }: {
    item: CatalogItem;
    colorId: string | null;
    onSelectColor(colorId: string): void;
    back: ReactNode;
  },
) {
  const selected = resolveColor(item, colorId);
  const swatchesRef = useRef<HTMLDivElement>(null);

  // A deep link may open on a colour past the row's edge; centre it once on
  // arrival, while a tapped swatch is already in view. Scrolls only the row:
  // scrollIntoView would also move the page.
  useEffect(() => {
    const row = swatchesRef.current;
    const active = row?.querySelector<HTMLElement>(".pdp__swatch.is-active");
    if (!row || !active) return;
    const offset = active.getBoundingClientRect().left - row.getBoundingClientRect().left;
    row.scrollLeft += offset - (row.clientWidth - active.offsetWidth) / 2;
  }, []);
  const tryon = useTryonCoordinator();
  const gate = useModelGatedTryon();

  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink)
    ? item.purchaseLink
    : null;

  return (
    <>
      <main className="main pdp">
        <div className="pdp__media">
          {back}
          <ProductGallery key={selected?.id} imageUrls={selected?.imageUrls ?? []} />
        </div>

        {item.storeName && <p className="pdp__store">{item.storeName}</p>}
        <h1 className="pdp__name">{item.name}</h1>
        <p className="pdp__price">{priceText(item.price)}</p>
        {hasColorChoice(item) && selected && (
          <div className="pdp__colors">
            {selected.name && <p className="pdp__colorlabel">{selected.name}</p>}
            <div className="pdp__swatches" ref={swatchesRef}>
              {item.colors.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  className={`pdp__swatch${c.id === selected.id ? " is-active" : ""}`}
                  aria-label={c.name ?? undefined}
                  aria-pressed={c.id === selected.id}
                  onClick={() => onSelectColor(c.id)}
                >
                  <FadeImage src={c.imageUrls[0]} alt="" loading="lazy" />
                </button>
              ))}
            </div>
          </div>
        )}
        {item.description && <p className="pdp__description">{item.description}</p>}

        {gate.choiceFailed && (
          <div className="errorcard">模特設定失敗，請稍後再試或換一張清楚的全身照。</div>
        )}
      </main>

      <div className="actionbar">
        {!selected
          ? <p className="pdp__note">這件商品還沒有照片，無法試穿。</p>
          : (
            <button
              type="button"
              className={`cta${gate.busy ? " is-loading" : ""}`}
              disabled={gate.busy}
              onClick={() => gate.start(() => tryon.fromProduct(item, selected))}
            >
              {gate.busy
                ? (
                  <span className="cta__spin">
                    <span className="spinner" aria-hidden="true" />
                    設定模特中…
                  </span>
                )
                : "開始試穿"}
            </button>
          )}

        {buyUrl && (
          <button
            type="button"
            className="btn-outline actionbar__secondary"
            onClick={() => openExternal(buyUrl)}
          >
            前往購買
          </button>
        )}
      </div>

      {gate.sheet}
    </>
  );
}

function seededItem(state: unknown): CatalogItem | null {
  if (typeof state !== "object" || state === null) return null;
  const item = (state as { item?: unknown }).item;
  if (typeof item !== "object" || item === null) return null;
  return typeof (item as CatalogItem).productId === "string"
    ? item as CatalogItem
    : null;
}
