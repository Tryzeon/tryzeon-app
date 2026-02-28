import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_header.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_info_section.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_size_table.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_store_info.dart';

class ProductDetailBody extends HookConsumerWidget {
  const ProductDetailBody({super.key, required this.productAsync, required this.onRetry});

  final AsyncValue<ShopProduct> productAsync;
  final VoidCallback onRetry;

  /// Skeleton data for loading state
  static const _skeletonProduct = ShopProduct(
    id: 'skeleton_product',
    storeInfo: ShopStoreInfo(
      id: 'skeleton_store',
      name: 'Loading Store Name',
      address: 'Loading Store Address',
    ),
    name: 'Loading Product Name here that is long',
    categories: {'Category 1', 'Category 2'},
    price: 8888.0,
    imagePath: 'skeleton_path',
    imageUrl: '',
    material: 'Loading Material Description',
  );

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Priority 1: Show data if available (even during loading or error)
    if (productAsync.hasValue) {
      return Skeletonizer(
        enabled: productAsync.isLoading,
        child: _ProductDetailContent(product: productAsync.requireValue),
      );
    }

    // Priority 2: Show skeleton when loading without data
    if (productAsync.isLoading) {
      return const Skeletonizer(
        enabled: true,
        child: _ProductDetailContent(product: _skeletonProduct),
      );
    }

    // Priority 3: Show error when failed without data
    return ErrorView(
      message: (productAsync.error! as Failure).displayMessage(context),
      onRetry: onRetry,
    );
  }
}

class _ProductDetailContent extends HookConsumerWidget {
  const _ProductDetailContent({required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Build category ID to name mapping
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryIdToName = categoriesAsync.maybeWhen(
      data: (final categories) => {for (final cat in categories) cat.id: cat.name},
      orElse: () => <String, String>{},
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header (Image, Categories, Name, Price)
          ProductHeader(product: product, categoryIdToName: categoryIdToName),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 20),

                // Store Info Section
                ProductStoreInfo(storeInfo: product.storeInfo),
                const SizedBox(height: 32),

                // Product Info Section (Material, Elasticity, Fit)
                if (product.elasticity != null ||
                    product.fit != null ||
                    (product.material != null && product.material!.isNotEmpty)) ...[
                  ProductInfoSection(product: product),
                  const SizedBox(height: 32),
                ],

                // Size Info Section
                if (product.sizes != null && product.sizes!.isNotEmpty) ...[
                  ProductSizeTable(sizes: product.sizes!),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),

          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
