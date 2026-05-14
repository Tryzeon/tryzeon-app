import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';

import 'product_card.dart';

class ProductGrid extends HookConsumerWidget {
  const ProductGrid({
    super.key,
    required this.productsAsync,
    required this.userProfile,
    required this.onRetry,
  });

  final AsyncValue<List<ShopProduct>> productsAsync;
  final UserProfile? userProfile;
  final VoidCallback onRetry;

  /// Skeleton data for loading state
  static final _skeletonProducts = [
    ShopProduct(
      id: 'skeleton_1',
      storeInfo: const ShopStoreInfo(
        id: 'skeleton_store',
        name: 'Loading Store',
        channels: StoreChannel.all,
      ),
      name: 'Loading Product Name',
      categoryIds: ['Category'],
      price: 8888,
      imagePaths: ['skeleton_path'],
      imageUrls: [],
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ),
    ShopProduct(
      id: 'skeleton_2',
      storeInfo: const ShopStoreInfo(
        id: 'skeleton_store',
        name: 'Loading Store',
        channels: StoreChannel.all,
      ),
      name: 'Loading Product Name',
      categoryIds: ['Category'],
      price: 8888,
      imagePaths: ['skeleton_path'],
      imageUrls: [],
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ),
    ShopProduct(
      id: 'skeleton_3',
      storeInfo: const ShopStoreInfo(
        id: 'skeleton_store',
        name: 'Loading Store',
        channels: StoreChannel.all,
      ),
      name: 'Loading Product Name',
      categoryIds: ['Category'],
      price: 8888,
      imagePaths: ['skeleton_path'],
      imageUrls: [],
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ),
    ShopProduct(
      id: 'skeleton_4',
      storeInfo: const ShopStoreInfo(
        id: 'skeleton_store',
        name: 'Loading Store',
        channels: StoreChannel.all,
      ),
      name: 'Loading Product Name',
      categoryIds: ['Category'],
      price: 8888,
      imagePaths: ['skeleton_path'],
      imageUrls: [],
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ),
  ];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Priority 1: Show data if available (even during loading or error)
    if (productsAsync.hasValue) {
      final products = productsAsync.value!;

      // Handle empty state
      if (products.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '目前沒有商品符合搜尋條件',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (final context, final index) {
            final product = products[index];
            final fitResult = FitCalculator.calculate(
              userProfile: userProfile,
              productSizes: product.sizes,
            );
            return ProductCard(product: product, fitResult: fitResult);
          },
        ),
      );
    }

    // Priority 2: Show skeleton when loading without data
    if (productsAsync.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _skeletonProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (final context, final index) {
              final product = _skeletonProducts[index];
              return ProductCard(product: product, fitResult: const FitResult());
            },
          ),
        ),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(
      message: productsAsync.error.displayMessage(context),
      onRetry: onRetry,
    );
  }
}
