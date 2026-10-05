import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

/// Applies every pick live and stays open: field and direction are picked
/// together, so closing on the field would force a reopen to flip direction.
class ProductSortSheet extends ConsumerWidget {
  const ProductSortSheet({super.key});

  static Future<void> show(final BuildContext context) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => const ProductSortSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final sort = ref.watch(productQueryProvider.select((final q) => q.sort));
    final colorScheme = Theme.of(context).colorScheme;

    void applySort(final SortCondition next) {
      ref.read(productQueryProvider.notifier).updateSort(next);
    }

    return AppSheet(
      title: '排序',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final key in allSortKeys)
            ListTile(
              title: Text(key.label),
              selected: key == sort.key,
              trailing: key == sort.key
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => applySort(sort.copyWith(key: key)),
            ),
        ],
      ),
      footer: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(sort.key.descendingLabel),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(sort.key.ascendingLabel),
          ),
        ],
        selected: {sort.ascending},
        onSelectionChanged: (final selection) =>
            applySort(sort.copyWith(ascending: selection.first)),
      ),
    );
  }
}
