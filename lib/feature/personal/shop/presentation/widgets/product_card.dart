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
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
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

    Future<void> handleTryon({final TryOnMode mode = TryOnMode.image}) async {
      ref
          .read(incrementTryonCountProvider)
          .call(productId: product.id, storeId: product.storeInfo.id)
          .ignore();

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

      await ref
          .read(tryOnCoordinatorProvider)
          .tryOnFromStorage(product.imagePaths, mode: mode);
    }

    final dotColor = switch (fitStatus) {
      null => null,
      FitStatus.perfect => AppColors.success,
      FitStatus.good => AppColors.warning,
      FitStatus.poor => AppColors.error,
    };

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.personalShopProductPath(product.id));
      },
      child: VisibilityDetector(
        key: Key('product-card-${product.id}'),
        onVisibilityChanged: onVisibilityChanged,
        child: Card(
          color: colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: product.imageUrls.isEmpty
                            ? const _ImagePlaceholder()
                            : CachedNetworkImage(
                                imageUrl: product.imageUrls.first,
                                cacheKey: product.imagePaths.isNotEmpty
                                    ? product.imagePaths.first
                                    : null,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (final context, final url) =>
                                    Container(color: colorScheme.surfaceContainerLow),
                                errorWidget: (final context, final url, final error) =>
                                    const _ImageErrorWidget(),
                              ),
                      ),
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
                            child: Skeleton.ignore(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: AppRadius.pillAll,
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.storeInfo.name.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            product.name,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '\$${product.price}',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dotColor != null)
                      Positioned(
                        top: AppSpacing.smMd,
                        right: AppSpacing.smMd,
                        child: Skeleton.ignore(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _ImageErrorWidget extends StatelessWidget {
  const _ImageErrorWidget();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}
