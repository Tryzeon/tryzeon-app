import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/dialogs/product_sort_dialog.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductListSection extends HookConsumerWidget {
  const ProductListSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final query = ref.watch(productQueryProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        return LayoutBuilder(
          builder: (final context, final constraints) {
            final minHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 400.0;

            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 50,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      query.searchQuery.isNotEmpty ? '沒有符合條件的商品' : '還沒有商品',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      query.searchQuery.isNotEmpty ? '試試清除搜尋關鍵字' : '點擊右下角按鈕新增商品',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (final context, final index) {
          return StoreProductCard(product: products[index]);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text('我的商品', style: textTheme.titleLarge),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.sort_rounded, color: colorScheme.primary),
                onPressed: () => showProductSortSheet(context),
                tooltip: '排序',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            style: textTheme.bodyMedium,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '搜尋商品名稱…',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        debounceTimer.value?.cancel();
                        searchController.clear();
                        ref.read(productQueryProvider.notifier).updateSearch('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        filteredProductsAsync.when(
          skipLoadingOnReload: true,
          skipError: true,
          loading: () => const Center(child: CircularProgressIndicator()),
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
