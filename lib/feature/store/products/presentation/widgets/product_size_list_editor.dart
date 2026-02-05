import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';

class ProductSizeListEditor extends StatelessWidget {
  const ProductSizeListEditor({
    super.key,
    required this.entries,
    required this.isCun,
    required this.onUnitChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ProductSizeEntryController> entries;
  final bool isCun;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.straighten_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '尺寸列表',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Row(
              children: [
                // Unit Toggle
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        selected: !isCun,
                        label: '切換為公分',
                        child: InkWell(
                          onTap: () => onUnitChanged(false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !isCun ? colorScheme.primary : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '公分',
                              style: textTheme.labelSmall?.copyWith(
                                color: !isCun
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: !isCun ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        selected: isCun,
                        label: '切換為寸',
                        child: InkWell(
                          onTap: () => onUnitChanged(true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCun ? colorScheme.primary : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '寸',
                              style: textTheme.labelSmall?.copyWith(
                                color: isCun
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isCun ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新增'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '尚未新增尺寸',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...List.generate(entries.length, (final index) {
            final entry = entries[index];
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '尺寸 ${index + 1}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            onPressed: () => onRemove(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: entry.nameController,
                        style: textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: '尺寸名稱 (如: S, M, XL)',
                          labelStyle: textTheme.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainer,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        validator: AppValidators.validateSizeName,
                      ),
                      const SizedBox(height: 16),
                      ...MeasurementType.values.map((final type) {
                        final valueController = entry.measurementControllers[type]!;
                        final offsetController = entry.offsetControllers[type]!;

                        // Dynamic Label
                        final label = isCun ? '${type.label}(寸)' : '${type.label}(公分)';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // 測量值輸入
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: valueController,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: label,
                                    labelStyle: textTheme.bodyMedium,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  validator: AppValidators.validateMeasurement,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Offset 控制
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '誤差範圍 (±)',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Material(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                _updateOffset(offsetController, -0.5),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(Icons.remove, size: 16),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.symmetric(
                                                horizontal: BorderSide(
                                                  color: colorScheme.outline.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            child: AnimatedBuilder(
                                              animation: offsetController,
                                              builder: (final context, final child) {
                                                return Text(
                                                  offsetController.text,
                                                  textAlign: TextAlign.center,
                                                  style: textTheme.bodyMedium,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Material(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                _updateOffset(offsetController, 0.5),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(Icons.add, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  void _updateOffset(final TextEditingController controller, final double delta) {
    final currentValue = double.tryParse(controller.text) ?? 0.0;
    final newValue = (currentValue + delta).clamp(0.0, 100.0); // 限制 offset 不小於 0

    // 處理浮點數精度問題
    controller.text = newValue.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
