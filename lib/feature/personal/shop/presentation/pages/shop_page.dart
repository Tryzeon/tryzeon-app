import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

import '../dialogs/filter_dialog.dart';
import '../widgets/ad_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/product_category_filter.dart';
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
      return Container(
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? colorScheme.onPrimary : colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: isActive ? colorScheme.onPrimary : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: handleShowFilterDialog,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.filter_list_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
        ),
      );
    }

    final filter = ShopFilter(
      searchQuery: searchQuery.value,
      sortOption: sortOption.value,
      minPrice: minPrice.value,
      maxPrice: maxPrice.value,
      types: selectedSubcategoryIds.value,
      userLocation: userLocation,
    );

    final productsAsync = ref.watch(shopProductsProvider(filter));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題欄
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '試衣間',
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '發現時尚新品',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 內容區域
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => refreshShopProducts(ref, filter),
                  color: colorScheme.primary,
                  child: LayoutBuilder(
                    builder: (final context, final constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔍 搜尋欄
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ShopSearchBar(
                                  onSearch: (final query) async {
                                    searchQuery.value = query.isEmpty ? null : query;
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 📢 廣告輪播
                              adsAsync.when(
                                data: (final ads) => AdBanner(adImages: ads),
                                loading: () => Skeletonizer(
                                  enabled: true,
                                  child: Skeleton.leaf(
                                    child: Container(
                                      height: 180,
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: colorScheme.surfaceContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                error: (final e, final s) => const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 24),

                              // 商品類型篩選標籤
                              Skeletonizer(
                                enabled: productCategoryTreeAsync.isLoading,
                                child: ProductCategoryFilter(
                                  categoryTree: productCategoryTreeAsync.value,
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
                                      selectedSubcategoryIds.value =
                                          selectedSubcategoryIds.value
                                              .where((final id) => id != subcategoryId)
                                              .toSet();
                                    } else {
                                      selectedSubcategoryIds.value = {
                                        ...selectedSubcategoryIds.value,
                                        subcategoryId,
                                      };
                                    }
                                  },
                                ),
                              ),

                              // Error state
                              if (productCategoryTreeAsync.hasError)
                                ErrorView(
                                  onRetry: () => ref.refresh(productCategoryTreeProvider),
                                  isCompact: true,
                                ),

                              const SizedBox(height: 24),

                              // 推薦商品標題
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
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
                                    Text(
                                      '推薦商品',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        buildComprehensiveSortButton(),
                                        const SizedBox(width: 8),
                                        buildPriceSortButton(),
                                        const SizedBox(width: 8),
                                        buildFilterButton(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 商品 Grid（可滾動）
                              productsAsync.when(
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
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: 0.7,
                                          ),
                                      itemBuilder: (final context, final index) {
                                        return const ProductCard(
                                          product: ShopProduct(
                                            id: 'dummy_id',
                                            storeInfo: ShopStoreInfo(
                                              id: 'dummy_store',
                                              name: 'Loading Store',
                                            ),
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
                                  onRetry: () =>
                                      ref.refresh(shopProductsProvider(filter)),
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
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        return ProductCard(
                                          product: product,
                                          fitStatus: fitStatus,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 32),
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
      ),
    );
  }
}
