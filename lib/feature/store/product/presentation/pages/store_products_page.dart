import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/app_page_header.dart';
import 'package:tryzeon/core/router/shells/store_tab.dart';
import 'package:tryzeon/core/router/shells/tab_reselect.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_sort_sheet.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_search_bar.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_status_tabs.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/store_add_product_fab.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/store_product_sliver_grid.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

class StoreProductsPage extends HookConsumerWidget {
  const StoreProductsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final scrollController = useScrollController();
    final floatingHeaderKey = useMemoized(GlobalKey.new);

    // A new query shows its results from the top, but never scrolls back past
    // the floating header: once the tabs are pinned they stay pinned.
    ref.listen(productQueryProvider, (final _, final _) {
      final headerExtent = floatingHeaderKey.currentContext?.size?.height;
      if (headerExtent == null || !scrollController.hasClients) return;
      if (scrollController.offset > headerExtent) {
        scrollController.jumpTo(headerExtent);
      }
    });

    ref.listen(tabReselectSignalProvider, (final _, final next) {
      if (next?.tab != StoreTab.products) return;
      if (!scrollController.hasClients || scrollController.offset <= 0) return;
      scrollController.animateTo(
        0,
        duration: AppDuration.slow,
        curve: AppCurves.emphasized,
      );
    });

    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => [
            ref.read(productsProvider.notifier).refresh(),
            ref.read(productAnalyticsSummariesProvider.notifier).refresh(),
          ].showFirstFailure(context),
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverFloatingHeader(
                child: ColoredBox(
                  key: floatingHeaderKey,
                  color: surface,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPageHeader(title: '我的商品', action: _SortButton()),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.smMd,
                        ),
                        child: ProductSearchBar(),
                      ),
                      SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: surface,
                  child: const ProductStatusTabs(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              const StoreProductSliverGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: const StoreAddProductFab(
        anchor: CoachMarkTarget.storeProductsAddFab,
      ),
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
