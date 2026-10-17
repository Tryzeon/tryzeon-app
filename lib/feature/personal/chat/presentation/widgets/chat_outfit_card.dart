import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_outfit_labels.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/product_outfit_actions.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/wardrobe_outfit_actions.dart';

class ChatOutfitCard extends ConsumerWidget {
  const ChatOutfitCard({super.key, required this.outfit});

  final ResolvedOutfit outfit;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final reason = outfit.reason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: _Collage.aspectRatio,
          child: ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: _Collage(pieces: outfitCollageOrder(outfit.pieces)),
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        Text(
          outfit.title,
          style: textTheme.headlineMedium?.copyWith(letterSpacing: -0.2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (reason != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            reason,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral40,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const Spacer(),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.smMd),
        Row(
          children: [
            Expanded(child: _PurchaseLine(pieces: outfit.pieces)),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => triggerOutfitTryon(context, ref, [
                for (final piece in outfit.pieces)
                  switch (piece) {
                    ResolvedProduct(:final product) => outfitPieceFromProduct(
                      ref,
                      product,
                    ),
                    ResolvedWardrobeItem(:final item) =>
                      outfitPieceFromWardrobeItem(item),
                  },
              ]),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('試穿整套'),
            ),
          ],
        ),
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
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColors.neutral40,
    );
    final purchase = outfitPurchase(pieces);
    if (purchase == null) return Text('全部來自你的衣櫃', style: secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          outfitPurchaseCountLabel(purchase, pieces.length),
          style: secondary,
          maxLines: 1,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          purchase.total.asTwd,
          style: textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

/// One frame for every look, so a rail of them lines up whatever the piece
/// count: 9:8 is the frame in which a trio's 2:1 lead and its stacked pair all
/// stand 3:4, like the shop photos they hold; a pair halves it.
class _Collage extends StatelessWidget {
  const _Collage({required this.pieces});

  final List<ResolvedItem> pieces;

  static const double aspectRatio = 9 / 8;

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
                  flex: 2,
                  child: _Cell(piece: pieces.first, labelled: labelled),
                ),
                const SizedBox(width: gap),
                Expanded(
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
      ResolvedProduct(:final product) => (
        ChatProductImage(product: product),
        () => context.push(
          AppRoutes.personalShopProductPath(product.id),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
