import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';

class ProductStyleSelector extends HookWidget {
  const ProductStyleSelector({super.key, required this.selectedStyles, this.onChanged});

  final ValueNotifier<List<ClothingStyle>?> selectedStyles;
  final ValueChanged<List<ClothingStyle>?>? onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentStyles = useListenable(selectedStyles);
    final styles = currentStyles.value ?? [];

    void showSelectionSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (final context) => _StyleSelectionSheet(
          selectedStyles: styles,
          onSelectionChanged: (final newStyles) {
            if (onChanged != null) {
              onChanged!(newStyles.isEmpty ? null : newStyles);
            } else {
              selectedStyles.value = newStyles.isEmpty ? null : newStyles;
            }
          },
        ),
      );
    }

    return GestureDetector(
      onTap: showSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: styles.isEmpty
                  ? Text(
                      '選擇風格標籤',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: styles
                          .map(
                            (final s) => Chip(
                              label: Text(s.label, style: textTheme.labelSmall),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StyleSelectionSheet extends HookWidget {
  const _StyleSelectionSheet({
    required this.selectedStyles,
    required this.onSelectionChanged,
  });

  final List<ClothingStyle> selectedStyles;
  final ValueChanged<List<ClothingStyle>> onSelectionChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentSelection = useState<Set<ClothingStyle>>(selectedStyles.toSet());
    final searchController = useTextEditingController();
    useListenable(searchController);

    void toggleSelection(final ClothingStyle style) {
      final newSet = {...currentSelection.value};
      if (newSet.contains(style)) {
        newSet.remove(style);
      } else {
        newSet.add(style);
      }
      currentSelection.value = newSet;
    }

    void saveAndClose() {
      onSelectionChanged(currentSelection.value.toList());
      Navigator.pop(context);
    }

    final searchQuery = searchController.text.trim().toLowerCase();

    // Filter styles by search
    final filteredStyles = useMemoized(() {
      if (searchQuery.isEmpty) return ClothingStyle.values;

      return ClothingStyle.values
          .where(
            (final s) =>
                s.label.toLowerCase().contains(searchQuery) ||
                s.value.toLowerCase().contains(searchQuery),
          )
          .toList();
    }, [searchQuery]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('選擇風格', style: textTheme.titleLarge),
                  TextButton(
                    onPressed: saveAndClose,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      textStyle: textTheme.titleMedium,
                    ),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '搜尋風格...',
                    hintStyle: textTheme.bodyMedium,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: filteredStyles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('沒有符合的風格', style: textTheme.bodyMedium),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredStyles.length,
                      itemBuilder: (final context, final index) {
                        final style = filteredStyles[index];
                        final isSelected = currentSelection.value.contains(style);
                        return InkWell(
                          onTap: () => toggleSelection(style),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (final value) => toggleSelection(style),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    style.label,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
