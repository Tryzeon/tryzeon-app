import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

/// `null` from sheet = dismissed (preserve existing); `(value: x)` = confirmed
/// (write `x`, which may itself be null when user explicitly cleared).
typedef ProductMaterialResult = ({String? value});

class ProductMaterialSheet extends HookWidget {
  const ProductMaterialSheet({super.key, required this.initialValue});

  final String? initialValue;

  static Future<ProductMaterialResult?> show({
    required final BuildContext context,
    required final String? initialValue,
  }) {
    return showAppSheet<ProductMaterialResult>(
      context: context,
      builder: (final _) => ProductMaterialSheet(initialValue: initialValue),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final initialValue = this.initialValue;
    final hasValue = initialValue != null && initialValue.isNotEmpty;
    final initialIsPreset = kMaterialPresets.contains(initialValue);
    final customController = useTextEditingController(
      text: initialIsPreset ? '' : initialValue,
    );
    final hasCustom = useValueListenable(
      customController,
    ).text.trim().isNotEmpty;

    void pop(final String? value) {
      Navigator.of(context).pop<ProductMaterialResult>((value: value));
    }

    void submitCustom() {
      final custom = customController.text.trim();
      if (custom.isEmpty) return;
      pop(custom);
    }

    return AppSheet(
      title: '選擇材質',
      trailing: hasValue
          ? TextButton(onPressed: () => pop(null), child: const Text('清除'))
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final preset in kMaterialPresets)
                  ChoiceChip(
                    label: Text(preset),
                    selected: preset == initialValue,
                    onSelected: (final _) => pop(preset),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '或自行輸入',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: customController,
              textInputAction: TextInputAction.done,
              onSubmitted: (final _) => submitCustom(),
              decoration: InputDecoration(
                hintText: '塑膠、再生纖維…',
                suffixIcon: IconButton(
                  tooltip: '使用自訂材質',
                  icon: const Icon(Icons.check_rounded),
                  onPressed: hasCustom ? submitCustom : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
