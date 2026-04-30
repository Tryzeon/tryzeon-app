import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

import '../dialogs/filter_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/product_category_filter.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_bar.dart';

class ShopPage extends HookConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoryTreeAsync = ref.watch(productCategoryTreeProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final adsAsync = ref.watch(shopAdsProvider);

    // 取得使用者位置（用於附近店家排序）
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.maybeWhen(
      data: (final location) => location,
      orElse: () => null,
    );

    // 過濾和排序狀態
    final sortOption = useState(ProductSortOption.latest);
    final minPrice = useState<int?>(null);
    final maxPrice = useState<int?>(null);
    final searchQuery = useState<String?>(null);

    final selectedRootId = useState<String?>(null);
    final selectedSubcategoryIds = useState<Set<String>>({});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortByLatest() {
      sortOption.value = ProductSortOption.latest;
    }

    void handleSortByPrice() {
      if (sortOption.value == ProductSortOption.priceLowToHigh) {
        sortOption.value = ProductSortOption.priceHighToLow;
      } else {
        sortOption.value = ProductSortOption.priceLowToHigh;
      }
    }

    void handleShowFilterDialog() {
      FilterDialog(
        context: context,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        onApply: (final newMin, final newMax) {
          minPrice.value = newMin;
          maxPrice.value = newMax;
        },
      );
    }

    Widget buildSortButton({
      required final String label,
      required final IconData icon,
      required final bool isActive,
      required final VoidCallback onTap,
    }) {
      return ChoiceChip(
        label: Text(label),
        avatar: Icon(icon, size: 16),
        selected: isActive,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      );
    }

    Widget buildComprehensiveSortButton() {
      final isActive = sortOption.value == ProductSortOption.latest;
      return buildSortButton(
        label: '綜合',
        icon: Icons.emoji_events_outlined,
        isActive: isActive,
        onTap: handleSortByLatest,
      );
    }

    Widget buildPriceSortButton() {
      final isActive =
          sortOption.value == ProductSortOption.priceLowToHigh ||
          sortOption.value == ProductSortOption.priceHighToLow;
      final isAscending = sortOption.value == ProductSortOption.priceLowToHigh;

      return buildSortButton(
        label: '價格',
        icon: !isActive || isAscending ? Icons.arrow_upward : Icons.arrow_downward,
        isActive: isActive,
        onTap: handleSortByPrice,
      );
    }

    Widget buildFilterButton() {
      return IconButton.filledTonal(
        icon: const Icon(Icons.filter_list_rounded, size: 18),
        onPressed: handleShowFilterDialog,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(AppSpacing.sm),
      );
    }

    final filter = ShopFilter(
      searchQuery: searchQuery.value,
      sortOption: sortOption.value,
      minPrice: minPrice.value,
      maxPrice: maxPrice.value,
      categories: selectedSubcategoryIds.value,
      userLocation: userLocation,
    );

    final productsAsync = ref.watch(shopProductsProvider(filter));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 頂部品牌標題
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text('Tryzeon', style: textTheme.displaySmall),
            ),

            // 內容區域
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    refreshProductCategories(ref),
                    refreshShopProducts(ref, filter),
                  ]);
                },
                color: colorScheme.primary,
                child: LayoutBuilder(
                  builder: (final context, final constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔍 搜尋欄
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: ShopSearchBar(
                                onSearch: (final query) async {
                                  searchQuery.value = query.isEmpty ? null : query;
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.mdLg),

                            // 📢 廣告輪播
                            AdBanner(adsAsync: adsAsync),
                            const SizedBox(height: AppSpacing.lg),

                            // 商品類型篩選標籤
                            ProductCategoryFilter(
                              categoryTreeAsync: productCategoryTreeAsync,
                              selectedRootId: selectedRootId.value,
                              selectedSubcategoryIds: selectedSubcategoryIds.value,
                              onRootSelected: (final rootId) {
                                selectedRootId.value = rootId;
                                selectedSubcategoryIds.value = {};
                              },
                              onSubcategoryToggle: (final subcategoryId) {
                                if (selectedSubcategoryIds.value.contains(
                                  subcategoryId,
                                )) {
                                  selectedSubcategoryIds.value = selectedSubcategoryIds
                                      .value
                                      .where((final id) => id != subcategoryId)
                                      .toSet();
                                } else {
                                  selectedSubcategoryIds.value = {
                                    ...selectedSubcategoryIds.value,
                                    subcategoryId,
                                  };
                                }
                              },
                              onRetry: () {
                                // Invalidate upstream provider to refetch from backend
                                ref.invalidate(productCategoriesProvider);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 推薦商品標題與排序
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECOMMENDED',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.smMd),
                                  Row(
                                    children: [
                                      buildComprehensiveSortButton(),
                                      const SizedBox(width: AppSpacing.sm),
                                      buildPriceSortButton(),
                                      const Spacer(),
                                      buildFilterButton(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // 商品 Grid（可滾動）
                            ProductGrid(
                              productsAsync: productsAsync,
                              userProfile: userProfile,
                              onRetry: () => refreshShopProducts(ref, filter),
                            ),

                            const SizedBox(height: 120), // 預留底部空白，避免被導覽列遮擋或增加滾動空間
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
