import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';

class ProductSeasonSelector extends HookWidget {
  const ProductSeasonSelector({super.key, required this.selectedSeasons, this.onChanged});

  final ValueNotifier<List<ProductSeason>?> selectedSeasons;
  final ValueChanged<List<ProductSeason>?>? onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final current = useListenable(selectedSeasons);
    final selected = current.value ?? [];

    void toggle(final ProductSeason season) {
      final newList = [...selected];
      if (newList.contains(season)) {
        newList.remove(season);
      } else {
        newList.add(season);
      }

      final result = newList.isEmpty ? null : newList;
      if (onChanged != null) {
        onChanged!(result);
      } else {
        selectedSeasons.value = result;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: ProductSeason.values.map((final season) {
        final isSelected = selected.contains(season);
        return FilterChip(
          label: Text(season.label, style: textTheme.bodyMedium),
          selected: isSelected,
          onSelected: (final _) => toggle(season),
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}
