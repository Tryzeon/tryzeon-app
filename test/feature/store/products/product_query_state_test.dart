import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/products/presentation/dialogs/product_sort_dialog.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_query_state.dart';

Product makeProduct({
  required final String id,
  required final String name,
  required final double price,
  required final List<String> categoryIds,
  required final DateTime createdAt,
  required final DateTime updatedAt,
}) {
  return Product(
    id: id,
    storeId: 'store-1',
    name: name,
    categoryIds: categoryIds,
    price: price,
    imagePaths: const [],
    imageUrls: const [],
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  final products = [
    makeProduct(
      id: '1',
      name: 'White Shirt',
      price: 500,
      categoryIds: const ['cat_top'],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 3),
    ),
    makeProduct(
      id: '2',
      name: 'denim Jeans',
      price: 1200,
      categoryIds: const ['cat_bottom'],
      createdAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 2),
    ),
    makeProduct(
      id: '3',
      name: 'Denim Jacket',
      price: 1800,
      categoryIds: const ['cat_outer'],
      createdAt: DateTime(2024, 1, 3),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  group('filterAndSortProducts', () {
    test('returns all products when query is empty', () {
      final result = filterAndSortProducts(products, const ProductQueryState());
      expect(result.map((final product) => product.id).toList(), ['3', '2', '1']);
    });

    test('filters by name case-insensitively', () {
      final result = filterAndSortProducts(
        products,
        const ProductQueryState(searchQuery: 'denim'),
      );

      expect(result.map((final product) => product.id).toList(), ['3', '2']);
    });

    test('sorts by price ascending', () {
      final result = filterAndSortProducts(
        products,
        const ProductQueryState(
          sort: SortCondition(field: SortField.price, ascending: true),
        ),
      );

      expect(result.map((final product) => product.id).toList(), ['1', '2', '3']);
    });
  });

  group('ProductQueryState', () {
    test('supports value equality for identical values', () {
      final first = const ProductQueryState(searchQuery: 'denim');
      final second = const ProductQueryState(searchQuery: 'denim');

      expect(first, second);
    });

    test('copyWith preserves unchanged fields', () {
      const original = ProductQueryState(searchQuery: 'denim');

      final copy = original.copyWith(searchQuery: 'jacket');

      expect(copy.searchQuery, 'jacket');
      expect(copy.sort, SortCondition.defaultSort);
    });
  });

  testWidgets('sort sheet only shows sort controls', (final tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (final context) {
                return TextButton(
                  onPressed: () => showProductSortSheet(context),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('排序方式'), findsOneWidget);
    expect(find.text('分類'), findsNothing);
  });
}
