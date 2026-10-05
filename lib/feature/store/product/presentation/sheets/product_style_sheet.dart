import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

class ProductStyleSheet extends HookWidget {
  const ProductStyleSheet({
    super.key,
    required this.initialSelection,
    required this.onChanged,
  });

  final Set<ClothingStyle> initialSelection;
  final ValueChanged<Set<ClothingStyle>> onChanged;

  static Future<void> show({
    required final BuildContext context,
    required final Set<ClothingStyle> initialSelection,
    required final ValueChanged<Set<ClothingStyle>> onChanged,
  }) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => ProductStyleSheet(
        initialSelection: initialSelection,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selection = useState<Set<ClothingStyle>>(initialSelection);
    final searchController = useTextEditingController();
    final query = useValueListenable(
      searchController,
    ).text.trim().toLowerCase();

    // Ordered once from the selection at open: re-sorting on every toggle
    // would move the row out from under the finger.
    final ordered = useMemoized(
      () => [
        ...ClothingStyle.values.where(initialSelection.contains),
        ...ClothingStyle.values.where(
          (final s) => !initialSelection.contains(s),
        ),
      ],
    );
    final styles = query.isEmpty
        ? ordered
        : ordered
              .where(
                (final s) =>
                    s.label.toLowerCase().contains(query) ||
                    s.value.toLowerCase().contains(query),
              )
              .toList();

    void toggle(final ClothingStyle style) {
      final next = selection.value.contains(style)
          ? ({...selection.value}..remove(style))
          : {...selection.value, style};
      selection.value = next;
      onChanged(next);
    }

    final count = selection.value.length;

    return AppSheet(
      title: count == 0 ? '選擇風格' : '選擇風格（$count）',
      height: AppSheetHeight.tall,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜尋風格...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: styles.isEmpty
                ? Center(
                    child: Text(
                      '沒有符合的風格',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: styles.length,
                    itemBuilder: (final context, final index) {
                      final style = styles[index];
                      return CheckboxListTile(
                        value: selection.value.contains(style),
                        onChanged: (final _) => toggle(style),
                        title: Text(style.label),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
