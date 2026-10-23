import { encodeBase64 } from "@std/encoding/base64";
import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import {
  classifyTryonError,
  runTryonJob,
  supabaseGenerationLog,
  supabaseQuota,
  supabaseTryonRecorder,
} from "../_shared/tryon/index.ts";
import type { QuotaSnapshot } from "../_shared/quota.ts";
import type { GarmentInput } from "../_shared/tryon/types.ts";
import { getAvatar as defaultGetAvatar } from "../_shared/user-profile.ts";
import type { ItemRef } from "../_shared/chat/index.ts";
import { fetchProductInfo, fetchProductRows } from "./product-card.ts";
import { fetchWardrobeItemInfo, fetchWardrobeRows } from "./wardrobe-card.ts";
import {
  type LineOutfit,
  outfitResultMessage,
  resolveOutfitPieces,
} from "./outfit-card.ts";
import { describeGarment as defaultDescribeGarment } from "./garment-analysis.ts";
import {
  chooseModelMessage,
  outfitProcessingMessage,
  outfitTryonErrorMessage,
  outfitUnavailableMessage,
  processingMessage,
  productProcessingMessage,
  productResultMessage,
  productTryonErrorMessage,
  productUnavailableMessage,
  resultMessage,
  tryonErrorMessage,
  type TryonJobErrorKind,
  wardrobeProcessingMessage,
  wardrobeResultMessage,
  wardrobeTryonErrorMessage,
  wardrobeUnavailableMessage,
} from "./messages.ts";
import { LineApi } from "./line-api.ts";
import {
  type ConversationStore,
  outfitTryonNote,
  photoNote,
  tryonNote,
  wardrobeTryonNote,
} from "./conversation.ts";
import type { DbClient } from "../_shared/supabase.ts";

export interface TryonHandlerDeps {
  admin: DbClient;
  line: LineApi;
  liffUrl: string;
  conversations: ConversationStore;
  getAvatar?: typeof defaultGetAvatar;
  getOrCreateUserId?: typeof defaultGetOrCreateUserId;
  runJob?: typeof runTryonJob;
}

interface Actor {
  userId: string;
  hasAvatar: boolean;
}

async function resolveActor(
  deps: TryonHandlerDeps,
  sourceUserId: string,
): Promise<Actor> {
  const getOrCreateUserId = deps.getOrCreateUserId ?? defaultGetOrCreateUserId;
  const getAvatar = deps.getAvatar ?? defaultGetAvatar;

  const userId = await getOrCreateUserId(
    deps.admin,
    { sub: sourceUserId },
    () => deps.line.getDisplayName(sourceUserId),
  );
  return {
    userId,
    hasAvatar: (await getAvatar(deps.admin, userId)) !== null,
  };
}

type TryonOutcome =
  | { ok: true; imageUrl: string }
  | { ok: false; kind: TryonJobErrorKind; quota: QuotaSnapshot | null };

async function runTryon(
  deps: TryonHandlerDeps,
  params: { userId: string; garments: GarmentInput[] },
): Promise<TryonOutcome> {
  const runJob = deps.runJob ?? runTryonJob;
  try {
    // Running the job on `admin` is safe here: a LINE event carries no Supabase
    // session, the avatar is resolved by the core from the user's own profile,
    // and a garment is inline base64, a product id, or a wardrobe item id — the
    // core resolves both id forms itself, binding the wardrobe one to
    // `job.userId`, so this adapter never forwards a client-supplied path.
    const result = await runJob(
      deps.admin,
      { userId: params.userId, garments: params.garments, mode: "image" },
      {
        quota: supabaseQuota(deps.admin),
        recordTryon: supabaseTryonRecorder(deps.admin),
        generations: supabaseGenerationLog(deps.admin),
      },
    );
    return { ok: true, imageUrl: result.imageUrl };
  } catch (err) {
    const { kind, quota } = tryonFailure(err);
    // "unknown" means a server-side fault (bad params, RLS, storage) rather
    // than a user error — log it so it leaves a trace beyond the pushed message.
    if (kind === "unknown") {
      console.error("line-webhook try-on failed:", err);
    }
    return { ok: false, kind, quota };
  }
}

export interface ImageTryonEvent {
  replyToken: string;
  sourceUserId: string;
  messageId: string;
}

export interface ImageTryonDeps extends TryonHandlerDeps {
  describeGarment?: typeof defaultDescribeGarment;
}

export async function handleImageTryon(
  deps: ImageTryonDeps,
  event: ImageTryonEvent,
): Promise<void> {
  const describeGarment = deps.describeGarment ?? defaultDescribeGarment;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [chooseModelMessage(deps.liffUrl)]);
    return;
  }

  await deps.line.reply(event.replyToken, [processingMessage()]);

  let bytes: Uint8Array;
  try {
    bytes = await deps.line.getContent(event.messageId);
  } catch (err) {
    console.warn("line-webhook failed to download garment image:", err);
    await deps.line.push(event.sourceUserId, [
      tryonErrorMessage("download", null),
    ]);
    return;
  }

  const base64 = encodeBase64(bytes);

  const described = describeGarment(userId, base64).catch((err) => {
    console.warn("line-webhook garment description failed:", err);
    return null;
  });

  const outcome = await runTryon(deps, {
    userId,
    garments: [{ images: [{ base64 }] }],
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? resultMessage(outcome.imageUrl)
      : tryonErrorMessage(outcome.kind, outcome.quota),
  ]);

  const description = await described;
  if (description !== null) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [
      ...prior,
      photoNote(description),
    ]);
  }
}

export interface ProductTryonEvent {
  replyToken: string;
  sourceUserId: string;
  productId: string;
}

export interface ProductTryonDeps extends TryonHandlerDeps {
  fetchProduct?: typeof fetchProductInfo;
}

/**
 * The product is read before anything is charged: `fetchProductInfo` returns
 * null for exactly the two cases the core would later reject as validation
 * errors — the row is gone, or it has no image — so checking here turns both
 * into a sentence the user understands at no quota cost.
 */
export async function handleProductTryon(
  deps: ProductTryonDeps,
  event: ProductTryonEvent,
): Promise<void> {
  const fetchProduct = deps.fetchProduct ?? fetchProductInfo;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [chooseModelMessage(deps.liffUrl)]);
    return;
  }

  const product = await fetchProduct(deps.admin, event.productId);
  if (!product) {
    await deps.line.reply(event.replyToken, [
      productUnavailableMessage(deps.liffUrl),
    ]);
    return;
  }

  await deps.line.reply(event.replyToken, [
    productProcessingMessage(product.name),
  ]);

  const outcome = await runTryon(deps, {
    userId,
    garments: [{ productId: product.id }],
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? productResultMessage(outcome.imageUrl, product)
      : productTryonErrorMessage(
        outcome.kind,
        outcome.quota,
        product,
        deps.liffUrl,
      ),
  ]);

  if (outcome.ok) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [
      ...prior,
      tryonNote(product),
    ]);
  }
}

export interface WardrobeTryonEvent {
  replyToken: string;
  sourceUserId: string;
  wardrobeItemId: string;
}

export interface WardrobeTryonDeps extends TryonHandlerDeps {
  fetchItem?: typeof fetchWardrobeItemInfo;
}

/**
 * The mirror of {@link handleProductTryon}, and deliberately not a
 * parameterisation of it: what is read, how the acknowledgement reads, the
 * result card, the error card and the transcript note all differ, which leaves
 * only the skeleton in common. `resolveActor` and `runTryon` are the parts that
 * genuinely are shared, and they already are.
 *
 * The garment goes in as `{ wardrobeItemId }` and never as a path. This adapter
 * holds the admin client, so a path it chose would be a path with nothing
 * checking whose it was; the core resolves the id against `job.userId` instead.
 */
export async function handleWardrobeTryon(
  deps: WardrobeTryonDeps,
  event: WardrobeTryonEvent,
): Promise<void> {
  const fetchItem = deps.fetchItem ?? fetchWardrobeItemInfo;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [chooseModelMessage(deps.liffUrl)]);
    return;
  }

  const item = await fetchItem(deps.admin, userId, event.wardrobeItemId);
  if (!item) {
    await deps.line.reply(event.replyToken, [wardrobeUnavailableMessage()]);
    return;
  }

  await deps.line.reply(event.replyToken, [
    wardrobeProcessingMessage(item.garmentTypeLabel),
  ]);

  const outcome = await runTryon(deps, {
    userId,
    garments: [{ wardrobeItemId: item.id }],
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? wardrobeResultMessage(outcome.imageUrl, item)
      : wardrobeTryonErrorMessage(outcome.kind, outcome.quota, item),
  ]);

  if (outcome.ok) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [
      ...prior,
      wardrobeTryonNote(item),
    ]);
  }
}

export interface OutfitTryonEvent {
  replyToken: string;
  sourceUserId: string;
  pieces: ItemRef[];
  title: string;
}

export interface OutfitTryonDeps extends TryonHandlerDeps {
  imagesBaseUrl: string;
  fetchProducts?: typeof fetchProductRows;
  fetchWardrobe?: typeof fetchWardrobeRows;
}

const garmentOf = ({ type, id }: ItemRef): GarmentInput =>
  type === "product" ? { productId: id } : { wardrobeItemId: id };

/**
 * Every piece is read before anything is charged, with the same rules the
 * core applies: an unlisted product or another sender's wardrobe item is
 * simply absent, and one absent piece means the look cannot be worn whole.
 */
export async function handleOutfitTryon(
  deps: OutfitTryonDeps,
  event: OutfitTryonEvent,
): Promise<void> {
  const fetchProducts = deps.fetchProducts ?? fetchProductRows;
  const fetchWardrobe = deps.fetchWardrobe ?? fetchWardrobeRows;
  const { userId, hasAvatar } = await resolveActor(deps, event.sourceUserId);

  if (!hasAvatar) {
    await deps.line.reply(event.replyToken, [chooseModelMessage(deps.liffUrl)]);
    return;
  }

  const idsOf = (type: ItemRef["type"]) =>
    event.pieces.filter((piece) => piece.type === type).map((piece) =>
      piece.id
    );
  const [products, wardrobe] = await Promise.all([
    fetchProducts(deps.admin, idsOf("product"), deps.imagesBaseUrl),
    fetchWardrobe(deps.admin, userId, idsOf("wardrobe")),
  ]);
  const pieces = resolveOutfitPieces(event.pieces, {
    product: (id) => products.get(id),
    wardrobe: (id) => wardrobe.get(id),
  });
  if (pieces === null) {
    await deps.line.reply(event.replyToken, [outfitUnavailableMessage()]);
    return;
  }
  const outfit: LineOutfit = { title: event.title, pieces };

  await deps.line.reply(event.replyToken, [
    outfitProcessingMessage(outfit.title),
  ]);

  const outcome = await runTryon(deps, {
    userId,
    garments: event.pieces.map(garmentOf),
  });

  await deps.line.push(event.sourceUserId, [
    outcome.ok
      ? outfitResultMessage(outcome.imageUrl, outfit, deps.liffUrl)
      : outfitTryonErrorMessage(outcome.kind, outcome.quota, outfit),
  ]);

  if (outcome.ok) {
    const prior = await deps.conversations.load(event.sourceUserId);
    await deps.conversations.save(event.sourceUserId, [
      ...prior,
      outfitTryonNote(outfit),
    ]);
  }
}

/**
 * A validation error is not user-actionable here — this adapter builds its own
 * params, and each kind of ref is checked for existence before any job starts —
 * so it is reported as an unknown fault.
 */
function tryonFailure(
  err: unknown,
): { kind: TryonJobErrorKind; quota: QuotaSnapshot | null } {
  const info = classifyTryonError(err);
  if (info === null) return { kind: "unknown", quota: null };
  switch (info.kind) {
    case "quota":
      return { kind: "quota", quota: info.quota };
    case "generation":
      return { kind: "generation", quota: null };
    case "busy":
      return { kind: "busy", quota: null };
    case "validation":
    case "rateLimit":
    case "missingAvatar":
      return { kind: "unknown", quota: null };
  }
}
