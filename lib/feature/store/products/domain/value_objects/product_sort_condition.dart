import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_sort_condition.freezed.dart';

enum SortField { name, price, createdAt, updatedAt }

@freezed
sealed class SortCondition with _$SortCondition {
  const factory SortCondition({
    required final SortField field,
    required final bool ascending,
  }) = _SortCondition;
  const SortCondition._();

  static const defaultSort = SortCondition(field: SortField.createdAt, ascending: false);
}
