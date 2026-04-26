import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

part 'product_query_state.freezed.dart';

@freezed
sealed class ProductQueryState with _$ProductQueryState {
  const factory ProductQueryState({
    @Default('') final String searchQuery,
    @Default(SortCondition.defaultSort) final SortCondition sort,
  }) = _ProductQueryState;
}

List<Product> filterAndSortProducts(
  final List<Product> products,
  final ProductQueryState query,
) {
  final normalizedSearchQuery = query.searchQuery.trim().toLowerCase();

  final filtered = products
      .where(
        (final product) =>
            normalizedSearchQuery.isEmpty ||
            product.name.toLowerCase().contains(normalizedSearchQuery),
      )
      .toList();

  filtered.sort((final a, final b) {
    final result = switch (query.sort.field) {
      SortField.name => a.name.compareTo(b.name),
      SortField.price => a.price.compareTo(b.price),
      SortField.createdAt => a.createdAt.compareTo(b.createdAt),
      SortField.updatedAt => a.updatedAt.compareTo(b.updatedAt),
    };

    return query.sort.ascending ? result : -result;
  });

  return filtered;
}
