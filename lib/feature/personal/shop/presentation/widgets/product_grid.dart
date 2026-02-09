import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
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

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return productsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => Skeletonizer(
        enabled: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (final context, final index) {
              return const ProductCard(
                product: ShopProduct(
                  id: 'dummy_id',
                  storeInfo: ShopStoreInfo(id: 'dummy_store', name: 'Loading Store'),
                  name: 'Loading Product Name',
                  types: {'Type'},
                  price: 8888,
                  imagePath: 'dummy_path',
                  imageUrl: '',
                ),
              );
            },
          ),
        ),
      ),
      error: (final error, final stack) => ErrorView(
        message: (error as Failure).displayMessage(context),
        onRetry: onRetry,
      ),
      data: (final displayedProducts) {
        if (displayedProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '目前沒有商品符合搜尋條件',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (final context, final index) {
              final product = displayedProducts[index];
              final fitStatus = FitCalculator.calculate(
                userProfile: userProfile,
                productSizes: product.sizes,
              );
              return ProductCard(product: product, fitStatus: fitStatus);
            },
          ),
        );
      },
    );
  }
}
