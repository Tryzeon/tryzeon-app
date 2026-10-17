import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/edit_product_page.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../../support/store_test_doubles.dart';

class _EmittingProducts extends ProductsNotifier {
  @override
  Future<List<Product>> build() async => [product('a'), product('b')];

  void emit(final List<Product> products) => state = AsyncData(products);
}

class _FailingProducts extends ProductsNotifier {
  var builds = 0;

  @override
  Future<List<Product>> build() async {
    builds++;
    throw const NetworkFailure();
  }
}

class _NoCategories extends ProductCategoriesNotifier {
  @override
  Future<List<ProductCategory>> build() async => const [];
}

void main() {
  testWidgets('keeps showing the product after it is deleted', (
    final tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(_EmittingProducts.new),
        productCategoriesProvider.overrideWith(_NoCategories.new),
      ],
      retry: (final _, final _) => null,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const EditProductPage(productId: 'a'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    (container.read(productsProvider.notifier) as _EmittingProducts).emit([
      product('b'),
    ]);
    await tester.pump();

    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('retry reloads the product list', (final tester) async {
    final products = _FailingProducts();
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(() => products),
        productCategoriesProvider.overrideWith(_NoCategories.new),
      ],
      retry: (final _, final _) => null,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const EditProductPage(productId: 'a'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(products.builds, 1);

    (tester.widget<ErrorView>(find.byType(ErrorView)).onRetry!)();
    await tester.pump();
    container.read(productByIdProvider('a'));

    expect(products.builds, 2);
  });
}
