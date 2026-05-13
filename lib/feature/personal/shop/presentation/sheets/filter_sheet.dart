import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

const double kMaxPrice = 3000;

class FilterSheet extends HookConsumerWidget {
  const FilterSheet({
    super.key,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  final int? minPrice;
  final int? maxPrice;
  final void Function(int? minPrice, int? maxPrice) onApply;

  static Future<void> show({
    required final BuildContext context,
    final int? minPrice,
    final int? maxPrice,
    required final void Function(int? minPrice, int? maxPrice) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final BuildContext context) {
        return FilterSheet(
          minPrice: minPrice,
          maxPrice: maxPrice,
          onApply: onApply,
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final initialMin = minPrice?.toDouble() ?? 0;
    final initialMax = maxPrice?.toDouble() ?? kMaxPrice;

    final priceRange = useState(RangeValues(initialMin, initialMax));
    final currentMinPrice = useState(minPrice);
    final currentMaxPrice = useState(maxPrice);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void applyFilters() {
      onApply(currentMinPrice.value, currentMaxPrice.value);
      Navigator.pop(context);
    }

    void resetFilters() {
      currentMinPrice.value = null;
      currentMaxPrice.value = null;
      priceRange.value = const RangeValues(0, kMaxPrice);
      applyFilters();
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              Text('篩選條件', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),

              // 價格範圍
              Text('價格範圍', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${priceRange.value.start.round()}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                  Text(
                    priceRange.value.end.round() >= kMaxPrice
                        ? '\$${kMaxPrice.round()}+'
                        : '\$${priceRange.value.end.round()}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              RangeSlider(
                values: priceRange.value,
                min: 0,
                max: kMaxPrice,
                divisions: 100,
                onChanged: (final RangeValues values) {
                  priceRange.value = values;
                  currentMinPrice.value = values.start.round();
                  currentMaxPrice.value = values.end >= kMaxPrice
                      ? null
                      : values.end.round();
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 按鈕
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: resetFilters,
                      child: const Text('清除'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(onPressed: applyFilters, child: const Text('套用')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
