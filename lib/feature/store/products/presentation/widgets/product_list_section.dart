import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_sort_sheet.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductListSection extends HookConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final query = ref.watch(productQueryProvider);
    final productCount = ref.watch(
      productsProvider.select((final async) => async.value?.length ?? 0),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final searchController = useTextEditingController(text: query.searchQuery);
    useListenable(searchController);
    final debounceTimer = useRef<Timer?>(null);

    useEffect(() {
      if (query.searchQuery != searchController.text) {
        searchController.value = TextEditingValue(
          text: query.searchQuery,
          selection: TextSelection.collapsed(offset: query.searchQuery.length),
        );
      }
      return null;
    }, [query.searchQuery]);

    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, const []);

    void onSearchChanged(final String value) {
      debounceTimer.value?.cancel();
      debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
        ref.read(productQueryProvider.notifier).updateSearch(value);
      });
    }

    Widget buildProductGrid(final List<Product> products) {
      if (products.isEmpty) {
        return _EmptyState(hasQuery: query.searchQuery.isNotEmpty);
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.6,
        ),
        itemCount: products.length,
        itemBuilder: (final context, final index) =>
            StoreProductCard(product: products[index]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Text(
                '我的商品 · $productCount',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ProductSortSheet.show(context),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '排序',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        TextField(
          controller: searchController,
          style: textTheme.bodyMedium,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: '搜尋商品名稱…',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onPressed: () {
                      debounceTimer.value?.cancel();
                      searchController.clear();
                      ref.read(productQueryProvider.notifier).updateSearch('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        filteredProductsAsync.when(
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
        ),
      ],
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
