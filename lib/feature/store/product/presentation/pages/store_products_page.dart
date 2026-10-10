import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_sort_sheet.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_list_section.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_search_bar.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_status_tabs.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/store_add_product_fab.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

class StoreProductsPage extends HookConsumerWidget {
  const StoreProductsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('我的商品', style: textTheme.headlineMedium),
                  ),
                  const _SortButton(),
                ],
              ),
            ),
            const ProductStatusTabs(),
            const SizedBox(height: AppSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
              child: ProductSearchBar(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => [
                  ref.read(productsProvider.notifier).refresh(),
                  ref
                      .read(productAnalyticsSummariesProvider.notifier)
                      .refresh(),
                ].showFirstFailure(context),
                child: const ProductListSection(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const StoreAddProductFab(),
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final sort = ref.watch(productQueryProvider.select((final q) => q.sort));

    return TextButton(
      onPressed: () => ProductSortSheet.show(context),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${sort.key.label} · '
            '${sort.key.directionLabel(ascending: sort.ascending)}',
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
        ],
      ),
    );
  }
}
