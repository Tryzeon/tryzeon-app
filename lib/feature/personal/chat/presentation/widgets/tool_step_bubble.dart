import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

class ToolUseBubble extends ConsumerWidget {
  const ToolUseBubble({super.key, required this.block});

  final ToolUseBlock block;

  // The backend only ever streams these two search tools as progress; the
  // default is unreachable but required for exhaustiveness, so keep it neutral.
  static String _verb(final String name) => switch (name) {
    'search_products' => '正在搜尋商品',
    'search_wardrobe' => '正在查詢衣櫃',
    _ => '正在搜尋',
  };

  // Keys mirror the search_products / search_wardrobe tool params (tools.ts) —
  // keep in sync if a filter is added there.
  static String _hint(
    final Map<String, dynamic> input,
    final Map<String, String> categoryNameByCode,
  ) {
    final parts = <String>[];
    for (final key in const [
      'category_code',
      'garment_type',
      'query',
      'gender',
      'styles',
      'seasons',
      'materials',
      'fits',
      'elasticities',
      'thicknesses',
      'channels',
      'tags',
    ]) {
      final v = input[key];
      if (v is String && v.trim().isNotEmpty) {
        final text = v.trim();
        parts.add(switch (key) {
          'category_code' => categoryNameByCode[text] ?? text,
          'garment_type' => GarmentType.tryFromString(text)?.displayName ?? text,
          _ => text,
        });
      } else if (v is List && v.isNotEmpty) {
        parts.add(v.join(' '));
      }
    }
    final minPrice = input['min_price'];
    final maxPrice = input['max_price'];
    if (minPrice is num || maxPrice is num) {
      parts.add('${minPrice ?? ''}–${maxPrice ?? ''}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final categories = ref.watch(productCategoriesProvider).value ?? const [];
    final categoryNameByCode = {for (final c in categories) c.code: c.name};
    final hint = _hint(block.input, categoryNameByCode);
    final label = [_verb(block.name), if (hint.isNotEmpty) hint].join(' · ');
    return _StepChip(icon: Icons.search, label: label);
  }
}

class ToolResultBubble extends StatelessWidget {
  const ToolResultBubble({super.key, required this.block});

  final ToolResultBlock block;

  @override
  Widget build(final BuildContext context) {
    final items = block.content['items'];
    final count = items is List ? items.length : 0;
    return _StepChip(icon: Icons.check, label: '找到 $count 件');
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
