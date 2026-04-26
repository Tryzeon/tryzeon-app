import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/products/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

void showProductSortSheet(final BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (final context) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.65,
      maxChildSize: 0.8,
      expand: false,
      builder: (final sheetContext, final scrollController) =>
          _SortSheetContent(scrollController: scrollController),
    ),
  );
}

class _SortSheetContent extends HookConsumerWidget {
  const _SortSheetContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentQuery = ref.read(productQueryProvider);
    final pendingSortField = useState<SortField>(currentQuery.sort.field);
    final pendingAscending = useState<bool>(currentQuery.sort.ascending);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void applyAndClose() {
      ref
          .read(productQueryProvider.notifier)
          .updateSort(
            SortCondition(
              field: pendingSortField.value,
              ascending: pendingAscending.value,
            ),
          );
      Navigator.of(context).pop();
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      Icons.sort_rounded,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('排序方式', style: textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      pendingSortField.value = SortCondition.defaultSort.field;
                      pendingAscending.value = SortCondition.defaultSort.ascending;
                    },
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    RadioGroup<SortField>(
                      groupValue: pendingSortField.value,
                      onChanged: (final value) {
                        if (value != null) {
                          pendingSortField.value = value;
                        }
                      },
                      child: Column(
                        children: SortField.values.map((final field) {
                          final isSelected = pendingSortField.value == field;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: InkWell(
                              onTap: () => pendingSortField.value = field,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                title: Text(
                                  field.label,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                leading: Radio<SortField>(
                                  value: field,
                                  fillColor: WidgetStateProperty.resolveWith((
                                    final states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return colorScheme.primary;
                                    }
                                    return null;
                                  }),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          '排序轉換',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        value: pendingAscending.value,
                        activeTrackColor: colorScheme.primary,
                        onChanged: (final value) => pendingAscending.value = value,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: applyAndClose,
                        child: const Text('套用'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
