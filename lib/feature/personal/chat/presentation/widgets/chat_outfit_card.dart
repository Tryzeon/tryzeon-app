import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_outfit_labels.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/product_outfit_actions.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/wardrobe_outfit_actions.dart';

/// The words lie over the collage's foot and let taps through to the cells
/// beneath, so only the try-on is a target of its own.
class ChatOutfitCard extends ConsumerWidget {
  const ChatOutfitCard({super.key, required this.outfit});

  final ResolvedOutfit outfit;

  static const double aspectRatio = 290 / 388;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: ChatCardStyle.radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Collage(pieces: outfitCollageOrder(outfit.pieces)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ChatImageScrim(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.smMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IgnorePointer(child: _Story(outfit: outfit)),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              child: _PurchaseLine(pieces: outfit.pieces),
                            ),
                          ),
                          TryonFab(
                            label: '試穿整套',
                            onTap: () => triggerOutfitTryon(context, ref, [
                              for (final piece in outfit.pieces)
                                switch (piece) {
                                  ResolvedProduct(
                                    :final product,
                                    :final color,
                                  ) =>
                                    outfitPieceFromProduct(
                                      ref,
                                      product,
                                      color: color,
                                    ),
                                  ResolvedWardrobeItem(:final item) =>
                                    outfitPieceFromWardrobeItem(item),
                                },
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.outfit});

  final ResolvedOutfit outfit;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onImage = theme.colorScheme.onPrimary;
    final reason = outfit.reason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          outfit.title,
          style: textTheme.titleLarge?.copyWith(
            color: onImage,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (reason != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            reason,
            style: textTheme.bodyMedium?.copyWith(
              color: onImage.withValues(alpha: ChatCardStyle.mutedTextAlpha),
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _PurchaseLine extends StatelessWidget {
  const _PurchaseLine({required this.pieces});

  final List<ResolvedItem> pieces;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onImage = theme.colorScheme.onPrimary;
    final purchase = outfitPurchase(pieces);
    if (purchase == null) {
      return Text(
        '全部來自你的衣櫃',
        style: textTheme.bodyMedium?.copyWith(color: onImage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          outfitPurchaseCountLabel(purchase, pieces.length),
          style: textTheme.bodySmall?.copyWith(
            color: onImage.withValues(alpha: ChatCardStyle.mutedTextAlpha),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          purchase.total.asTwd,
          style: textTheme.titleMedium?.copyWith(
            color: onImage,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Collage extends StatelessWidget {
  const _Collage({required this.pieces});

  final List<ResolvedItem> pieces;

  @override
  Widget build(final BuildContext context) {
    const gap = AppSpacing.xxs;
    final labelled = pieces.any((final piece) => piece is ResolvedProduct);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: pieces.length < 3
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, piece) in pieces.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(
                    child: _Cell(piece: piece, labelled: labelled),
                  ),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _Cell(piece: pieces.first, labelled: labelled),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, piece) in pieces.skip(1).indexed) ...[
                        if (i > 0) const SizedBox(height: gap),
                        Expanded(
                          child: _Cell(piece: piece, labelled: labelled),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// The photos carry no prices: the footer totals what is left to buy, and only
/// an owned piece is marked, so an unmarked cell reads as one to buy. A look
/// made only of owned pieces needs no marks: the footer already says so.
class _Cell extends StatelessWidget {
  const _Cell({required this.piece, required this.labelled});

  final ResolvedItem piece;
  final bool labelled;

  @override
  Widget build(final BuildContext context) {
    final (image, onTap, tag) = switch (piece) {
      ResolvedProduct(:final product, :final color) => (
        ChatProductImage(product: product, color: color),
        () => context.push(
          AppRoutes.personalShopProductPath(
            product.id,
            colorId: product.colors.distinguishing(color)?.id,
          ),
          extra: product,
        ),
        null,
      ),
      ResolvedWardrobeItem(:final item) => (
        ChatWardrobeImage(imagePath: item.imagePath),
        () => context.push(AppRoutes.personalWardrobeItemPath(item.id)),
        labelled ? const ChatImageTag.wardrobe() : null,
      ),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: ChatCardStyle.cutoutBackdrop,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (tag != null) ChatImageTagSlot(tag: tag),
          ],
        ),
      ),
    );
  }
}
