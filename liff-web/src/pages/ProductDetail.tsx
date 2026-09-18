import { useEffect, useState, type ReactNode } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { fetchProduct, type CatalogItem } from "../api/catalog";
import { AvatarUploadButton, AvatarUploadTip } from "../components/AvatarUpload";
import { Header } from "../components/Header";
import { ChevronLeftIcon } from "../components/icons";
import { ProductGallery } from "../components/ProductGallery";
import { useTryonCoordinator } from "../hooks/useTryonCoordinator";
import { isExternalUrl, openExternal } from "../lib/liff";
import { useAvatar } from "../state/AvatarProvider";

type Load =
  | { status: "loading" }
  | { status: "ready"; item: CatalogItem }
  | { status: "missing" }
  | { status: "error" };

/** This page is done the moment try-on is tapped: the coordinator moves the
 * user to home, and the result lands in that gallery. */
export function ProductDetail() {
  const { id } = useParams<{ id: string }>();
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
  // straight out of this app.
  function goBack() {
    if (location.key === "default") navigate("/");
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
        ? <Detail item={load.item} back={back} />
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

function Detail({ item, back }: { item: CatalogItem; back: ReactNode }) {
  const avatar = useAvatar();
  const tryon = useTryonCoordinator();

  const buyUrl = item.purchaseLink && isExternalUrl(item.purchaseLink)
    ? item.purchaseLink
    : null;
  const hasPhotos = item.imageUrls.length > 0;

  async function pickAvatarAndTryon(file: File) {
    if (await avatar.replace(file)) await tryon.fromProduct(item);
  }

  return (
    <>
      <main className="main pdp">
        <div className="pdp__media">
          {back}
          <ProductGallery imageUrls={item.imageUrls} />
        </div>

        {item.storeName && <p className="pdp__store">{item.storeName}</p>}
        <h1 className="pdp__name">{item.name}</h1>
        {item.price != null && <p className="pdp__price">NT${item.price}</p>}
        {item.description && <p className="pdp__description">{item.description}</p>}

        {hasPhotos && !avatar.hasAvatar && <AvatarUploadTip />}
      </main>

      <div className="actionbar">
        {!hasPhotos
          ? <p className="pdp__note">這件商品還沒有照片，無法試穿。</p>
          : avatar.hasAvatar
          ? (
            <button
              type="button"
              className="cta"
              onClick={() => tryon.fromProduct(item)}
            >
              開始試穿
            </button>
          )
          : <AvatarUploadButton busy={avatar.busy} onPick={pickAvatarAndTryon} />}

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
