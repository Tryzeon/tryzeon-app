import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_fit_sheet.dart';

class ProductFitSelector extends StatelessWidget {
  const ProductFitSelector({super.key, required this.selectedFit});

  final ValueNotifier<String?> selectedFit;

  Future<void> _openSheet(final BuildContext context) async {
    final result = await ProductFitSheet.show(
      context: context,
      initialValue: selectedFit.value,
    );
    if (result == null) return;
    selectedFit.value = result.value;
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: selectedFit,
      builder: (final context, final value, final _) {
        final isEmpty = value == null || value.isEmpty;
        return InkWell(
          onTap: () => _openSheet(context),
          borderRadius: AppRadius.inputAll,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? '選擇或輸入版型' : value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
