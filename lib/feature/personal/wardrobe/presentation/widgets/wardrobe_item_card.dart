import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class WardrobeItemCard extends ConsumerWidget {
  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final WardrobeItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final imageFileAsync = ref.watch(wardrobeItemImageProvider(item.imagePath));

    final colorScheme = Theme.of(context).colorScheme;

    Widget buildFallback({final VoidCallback? onRetry}) {
      return InkWell(
        onTap: onRetry,
        child: Container(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.cardAll,
              side: BorderSide(
                color: colorScheme.primary,
                width: AppStroke.regular,
              ),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageFileAsync.when(
              data: (final file) => Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (final context, final error, final stackTrace) =>
                    buildFallback(),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: AppStroke.regular,
                ),
              ),
              error: (final error, final stack) => buildFallback(
                onRetry: () =>
                    ref.refresh(wardrobeItemImageProvider(item.imagePath)),
              ),
            ),
            if (isSelected) ...[
              ColoredBox(
                color: colorScheme.primaryContainer.withValues(
                  alpha: AppOpacity.strong,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: CircleAvatar(
                  key: const Key('wardrobe-card-selected-badge'),
                  radius: AppSpacing.sm + AppSpacing.xxs,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.check_rounded,
                    size: AppSpacing.md,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
