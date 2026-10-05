import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/filter_chip_group.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';

const double kMaxPrice = 3000;
const double _priceStep = 100;
const _fullPriceRange = RangeValues(0, kMaxPrice);

/// Picks stay local until 套用 — applying live would refetch the grid behind
/// the sheet on every tap — so a dismiss discards them.
class FilterSheet extends HookConsumerWidget {
  const FilterSheet({super.key});

  static Future<void> show({required final BuildContext context}) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => const FilterSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final initial = useMemoized(() => ref.read(shopFilterProvider));

    final priceRange = useState(
      RangeValues(
        initial.minPrice?.toDouble() ?? 0,
        initial.maxPrice?.toDouble() ?? kMaxPrice,
      ),
    );
    final selectedChannels = useState<Set<StoreChannel>>({
      ...?initial.channels,
    });
    final selectedFits = useState<Set<ProductFit>>({...?initial.fits});
    final selectedElasticities = useState<Set<ProductElasticity>>({
      ...?initial.elasticities,
    });
    final selectedThicknesses = useState<Set<ProductThickness>>({
      ...?initial.thicknesses,
    });
    final selectedSeasons = useState<Set<ProductSeason>>({...?initial.seasons});
    final selectedStyles = useState<Set<ClothingStyle>>({...?initial.styles});
    final selectedMaterials = useState<Set<String>>({...?initial.materials});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final minPrice = priceRange.value.start <= 0
        ? null
        : priceRange.value.start.round();
    final maxPrice = priceRange.value.end >= kMaxPrice
        ? null
        : priceRange.value.end.round();

    final conditionCount =
        selectedChannels.value.length +
        selectedFits.value.length +
        selectedElasticities.value.length +
        selectedThicknesses.value.length +
        selectedSeasons.value.length +
        selectedStyles.value.length +
        selectedMaterials.value.length +
        (minPrice != null || maxPrice != null ? 1 : 0);

    void resetFilters() {
      priceRange.value = _fullPriceRange;
      selectedChannels.value = {};
      selectedFits.value = {};
      selectedElasticities.value = {};
      selectedThicknesses.value = {};
      selectedSeasons.value = {};
      selectedStyles.value = {};
      selectedMaterials.value = {};
    }

    void applyFilters() {
      ref.read(shopFilterProvider.notifier)
        ..setPriceRange(min: minPrice, max: maxPrice)
        ..setChannels(selectedChannels.value)
        ..setFits(selectedFits.value)
        ..setElasticities(selectedElasticities.value)
        ..setThicknesses(selectedThicknesses.value)
        ..setSeasons(selectedSeasons.value)
        ..setStyles(selectedStyles.value)
        ..setMaterials(selectedMaterials.value);
      Navigator.of(context).pop();
    }

    return AppSheet(
      title: '篩選條件',
      height: AppSheetHeight.tall,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterChipGroup<StoreChannel>(
              title: '販售通路',
              options: StoreChannel.values,
              selected: selectedChannels.value,
              labelOf: (final c) => c.label,
              onChanged: (final next) => selectedChannels.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('價格範圍', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceRange.value.start.round().asTwd,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  maxPrice == null
                      ? '${kMaxPrice.round().asTwd}+'
                      : maxPrice.asTwd,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: priceRange.value,
              max: kMaxPrice,
              divisions: kMaxPrice ~/ _priceStep,
              onChanged: (final values) => priceRange.value = values,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<ProductFit>(
              title: '版型',
              options: ProductFit.values,
              selected: selectedFits.value,
              labelOf: (final f) => f.label,
              onChanged: (final next) => selectedFits.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<ProductElasticity>(
              title: '彈性',
              options: ProductElasticity.values,
              selected: selectedElasticities.value,
              labelOf: (final e) => e.label,
              onChanged: (final next) => selectedElasticities.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<ProductThickness>(
              title: '厚度',
              options: ProductThickness.values,
              selected: selectedThicknesses.value,
              labelOf: (final t) => t.label,
              onChanged: (final next) => selectedThicknesses.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<ProductSeason>(
              title: '季節',
              options: ProductSeason.values,
              selected: selectedSeasons.value,
              labelOf: (final s) => s.label,
              onChanged: (final next) => selectedSeasons.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<ClothingStyle>(
              title: '風格',
              options: ClothingStyle.values,
              selected: selectedStyles.value,
              labelOf: (final s) => s.label,
              onChanged: (final next) => selectedStyles.value = next,
            ),
            const SizedBox(height: AppSpacing.lg),

            FilterChipGroup<String>(
              title: '材質',
              options: kMaterialPresets,
              selected: selectedMaterials.value,
              labelOf: (final m) => m,
              onChanged: (final next) => selectedMaterials.value = next,
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: conditionCount == 0 ? null : resetFilters,
              child: const Text('清除'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: applyFilters,
              child: Text(conditionCount == 0 ? '套用' : '套用（$conditionCount）'),
            ),
          ),
        ],
      ),
    );
  }
}
