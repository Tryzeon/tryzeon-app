import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductListSection extends HookConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final query = ref.watch(productQueryProvider);

    Widget buildProductGrid(final List<Product> products) {
      if (products.isEmpty) {
        return _EmptyState(hasQuery: query.searchQuery.isNotEmpty);
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.6,
        ),
        itemCount: products.length,
        itemBuilder: (final context, final index) =>
            StoreProductCard(product: products[index]),
      );
    }

    return filteredProductsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (final error, final stack) => ErrorView(
        message: error.displayMessage(context),
        onRetry: () => refreshProducts(ref),
      ),
      data: buildProductGrid,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(hasQuery ? '沒有符合條件的商品' : '還沒有商品', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasQuery ? '試試清除搜尋關鍵字' : '點擊右下角按鈕新增商品',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
