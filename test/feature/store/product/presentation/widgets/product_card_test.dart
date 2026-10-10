import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeCategories extends ProductCategoriesNotifier {
  @override
  Future<List<ProductCategory>> build() async => const [];
}

class _FakeAnalytics extends ProductAnalyticsSummariesNotifier {
  @override
  Future<List<ProductAnalyticsSummary>> build() async => const [];
}

class _FakeProductEdit extends ProductEditNotifier {
  final statuses = <ProductStatus>[];

  @override
  ProductMutation? build() => null;

  @override
  Future<Result<void, Failure>> setStatus({
    required final Product product,
    required final ProductStatus status,
  }) async {
    statuses.add(status);
    return const Ok(null);
  }
}

final _product = Product(
  storeId: 's1',
  name: 'White Tee',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 590,
  imagePaths: const [],
  imageUrls: const [],
  id: 'p1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('archives an active product from the card menu', (
    final tester,
  ) async {
    final edit = _FakeProductEdit();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productCategoriesProvider.overrideWith(_FakeCategories.new),
          productAnalyticsSummariesProvider.overrideWith(_FakeAnalytics.new),
          productEditProvider.overrideWith(() => edit),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: StoreProductCard(product: _product),
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.byTooltip('更多操作'));
    await settle(tester);

    expect(find.text(_product.name), findsNWidgets(2));

    await tester.tap(find.text('下架商品'));
    await settle(tester);

    expect(edit.statuses, [ProductStatus.archived]);
    expect(find.text('下架商品'), findsNothing);
  });

  testWidgets('opens the editor from the card menu', (final tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final _, final _) => Scaffold(
            body: SizedBox(
              width: 200,
              child: StoreProductCard(product: _product),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.dashboardProductDetail,
          builder: (final _, final state) =>
              Text('editing ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productCategoriesProvider.overrideWith(_FakeCategories.new),
          productAnalyticsSummariesProvider.overrideWith(_FakeAnalytics.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.byTooltip('更多操作'));
    await settle(tester);
    await tester.tap(find.text('編輯商品'));
    await settle(tester);

    expect(find.text('editing ${_product.id}'), findsOneWidget);
    expect(find.text('編輯商品'), findsNothing);
  });
}
