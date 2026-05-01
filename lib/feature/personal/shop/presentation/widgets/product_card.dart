import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/main/personal_entry_scope.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_status.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
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

    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final hasVideoAccess = capabilitiesAsync.maybeWhen(
      data: (final capabilities) => capabilities.hasVideoAccess,
      orElse: () => false,
    );

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
          return AppColors.success;
        case FitStatus.good:
          return AppColors.warning;
        case FitStatus.poor:
          return AppColors.error;
      }
    }

    Future<void> handleTryon({final TryOnMode mode = TryOnMode.image}) async {
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

      final personalEntry = PersonalEntryScope.of(context);
      await personalEntry?.tryOnFromStorage(product.imagePaths, mode: mode);
    }

    Widget buildTryonButton() {
      final buttonColor = fitStatus == null
          ? colorScheme.primary
          : getFitColor(fitStatus!);

      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: buttonColor, borderRadius: AppRadius.pillAll),
        child: Icon(Icons.auto_awesome, color: colorScheme.onPrimary, size: 20),
      );
    }

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.personalShopProductPath(product.id));
      },
      child: VisibilityDetector(
        key: Key('product-card-${product.id}'),
        onVisibilityChanged: onVisibilityChanged,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : '',
                      cacheKey: product.imagePaths.isNotEmpty
                          ? product.imagePaths.first
                          : null,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (final context, final url) => Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      ),
                      errorWidget: (final context, final url, final error) =>
                          const Center(child: Icon(Icons.error_outline)),
                    ),
                    // Try-on button with fit color at bottom right
                    Positioned(
                      bottom: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            TryOnModeSheet.show(
                              context: context,
                              hasVideoAccess: hasVideoAccess,
                              onModeSelected: (final mode) => handleTryon(mode: mode),
                            );
                          },
                          borderRadius: AppRadius.pillAll,
                          child: Skeleton.ignore(child: buildTryonButton()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.smMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '\$${product.price}',
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                    ),
                    Text(
                      product.storeInfo.name.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
