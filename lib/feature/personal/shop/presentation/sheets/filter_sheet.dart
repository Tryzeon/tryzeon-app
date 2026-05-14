import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

const double kMaxPrice = 3000;

class FilterSheet extends HookWidget {
  const FilterSheet({
    super.key,
    this.minPrice,
    this.maxPrice,
    required this.channels,
    required this.onApply,
  });

  final int? minPrice;
  final int? maxPrice;
  final Set<StoreChannel> channels;
  final void Function(int? minPrice, int? maxPrice, Set<StoreChannel> channels) onApply;

  static Future<void> show({
    required final BuildContext context,
    final int? minPrice,
    final int? maxPrice,
    required final Set<StoreChannel> channels,
    required final void Function(int? minPrice, int? maxPrice, Set<StoreChannel> channels)
    onApply,
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
          channels: channels,
          onApply: onApply,
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final initialMin = minPrice?.toDouble() ?? 0;
    final initialMax = maxPrice?.toDouble() ?? kMaxPrice;

    final priceRange = useState(RangeValues(initialMin, initialMax));
    final currentMinPrice = useState(minPrice);
    final currentMaxPrice = useState(maxPrice);
    final selectedChannels = useState<Set<StoreChannel>>({...channels});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final canApply = selectedChannels.value.isNotEmpty;

    void applyFilters() {
      if (!canApply) return;
      onApply(currentMinPrice.value, currentMaxPrice.value, selectedChannels.value);
      Navigator.pop(context);
    }

    void resetFilters() {
      currentMinPrice.value = null;
      currentMaxPrice.value = null;
      priceRange.value = const RangeValues(0, kMaxPrice);
      selectedChannels.value = StoreChannel.values.toSet();
      onApply(null, null, selectedChannels.value);
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

              // 販售通路
              Text('販售通路', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: StoreChannel.values.map((final channel) {
                  final isSelected = selectedChannels.value.contains(channel);
                  return FilterChip(
                    label: Text(channel.label),
                    selected: isSelected,
                    onSelected: (final v) {
                      final next = {...selectedChannels.value};
                      if (v) {
                        next.add(channel);
                      } else {
                        next.remove(channel);
                      }
                      selectedChannels.value = next;
                    },
                  );
                }).toList(),
              ),
              if (!canApply) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '請至少選擇一個通路',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],

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
                    child: FilledButton(
                      onPressed: canApply ? applyFilters : null,
                      child: const Text('套用'),
                    ),
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
