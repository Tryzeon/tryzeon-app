import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/products/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

class ProductSortSheet extends HookConsumerWidget {
  const ProductSortSheet({super.key});

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) => const ProductSortSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentQuery = ref.read(productQueryProvider);
    final pendingSortField = useState<SortField>(currentQuery.sort.field);
    final pendingAscending = useState<bool>(currentQuery.sort.ascending);

    final textTheme = Theme.of(context).textTheme;

    void applySort() {
      ref
          .read(productQueryProvider.notifier)
          .updateSort(
            SortCondition(
              field: pendingSortField.value,
              ascending: pendingAscending.value,
            ),
          );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text('排序', style: textTheme.titleMedium),
          ),
          RadioGroup<SortField>(
            groupValue: pendingSortField.value,
            onChanged: (final v) {
              if (v != null) {
                pendingSortField.value = v;
                applySort();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: SortField.values
                  .map(
                    (final field) =>
                        RadioListTile<SortField>(value: field, title: Text(field.label)),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text('由小到大', style: textTheme.titleSmall)),
                Switch(
                  value: pendingAscending.value,
                  onChanged: (final v) {
                    pendingAscending.value = v;
                    applySort();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
