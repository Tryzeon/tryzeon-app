import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class WardrobeItemCard extends ConsumerWidget {
  const WardrobeItemCard({super.key, required this.item});
  final WardrobeItem item;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final imageFileAsync = ref.watch(wardrobeItemImageProvider(item.imagePath));

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.personalWardrobeItemPath(item.id));
        },
        child: imageFileAsync.when(
          data: (final file) => Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (final context, final error, final stackTrace) {
              return Container(
                decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: AppStroke.regular)),
          error: (final error, final stack) => InkWell(
            onTap: () => ref.refresh(wardrobeItemImageProvider(item.imagePath)),
            child: Container(
              decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
