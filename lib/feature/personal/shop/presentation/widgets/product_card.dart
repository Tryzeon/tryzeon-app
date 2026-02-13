import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_status.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/product_detail_page.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductCard extends HookConsumerWidget {
  const ProductCard({super.key, required this.product, this.fitStatus});

  final ShopProduct product;
  final FitStatus? fitStatus;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasLoggedView = useState(false);

    void onVisibilityChanged(final VisibilityInfo info) {
      // Skip analytics for skeleton products
      if (product.id.startsWith('skeleton_')) return;

      if (info.visibleFraction > AppConstants.productVisibilityThreshold &&
          !hasLoggedView.value) {
        hasLoggedView.value = true;
        ref
            .read(incrementViewCountProvider)
            .call(productId: product.id, storeId: product.storeInfo.id)
            .ignore();
      }
    }

    Color getFitColor(final FitStatus status) {
      switch (status) {
        case FitStatus.perfect:
          return Colors.green;
        case FitStatus.good:
          return Colors.amber;
        case FitStatus.poor:
          return Colors.red;
      }
    }

    Future<void> handleTryon() async {
      // 記錄虛擬試穿點擊次數 (非同步執行，不阻塞 UI)
      ref
          .read(incrementTryonCountProvider)
          .call(productId: product.id, storeId: product.storeInfo.id)
          .ignore();

      // 如果契合度為紅色，彈出確認視窗
      if (fitStatus == FitStatus.poor) {
        final result = await showOkCancelAlertDialog(
          context: context,
          title: '尺寸不合',
          message: '這件衣服沒有符合你的尺寸，是否還要繼續試穿？',
          okLabel: '繼續試穿',
          cancelLabel: '取消',
        );

        if (result != OkCancelResult.ok) {
          return;
        }
      }

      if (!context.mounted) return;

      final personalEntry = PersonalEntry.of(context);
      await personalEntry?.tryOnFromStorage(product.imagePath);
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (final context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: VisibilityDetector(
        key: Key('product-card-${product.id}'),
        onVisibilityChanged: onVisibilityChanged,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        cacheKey: product.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (final context, final url) => Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                        errorWidget: (final context, final url, final error) =>
                            const Center(child: Icon(Icons.error_outline)),
                      ),
                    ),
                    // Try-on button with fit color at bottom right
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: handleTryon,
                          borderRadius: BorderRadius.circular(20),
                          child: Skeleton.ignore(
                            child: Builder(
                              builder: (final context) {
                                final buttonColor = fitStatus == null
                                    ? colorScheme.primary
                                    : getFitColor(fitStatus!);

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: buttonColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: buttonColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price}',
                      style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                    ),
                    Text(
                      product.storeInfo.name,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
