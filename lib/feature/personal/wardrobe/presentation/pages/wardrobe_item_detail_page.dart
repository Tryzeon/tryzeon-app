import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../mappers/category_ui_mapper.dart';

class WardrobeItemDetailPage extends HookConsumerWidget {
  const WardrobeItemDetailPage({super.key, required this.item});
  final WardrobeItem item;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final imageFileAsync = ref.watch(wardrobeItemImageProvider(item.imagePath));

    Future<void> handleDelete() async {
      final confirmResult = await showOkCancelAlertDialog(
        context: context,
        title: '刪除衣物',
        message: '你確定要刪除這件衣物嗎？',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (confirmResult != OkCancelResult.ok || !context.mounted) return;

      final deleteWardrobeItemUseCase = ref.read(deleteWardrobeItemUseCaseProvider);
      final result = await deleteWardrobeItemUseCase(item);

      if (!context.mounted) return;

      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
        Navigator.pop(context);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    Widget buildTagChips() {
      if (item.tags.isEmpty) {
        return Text(
          '尚無標籤',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        );
      }

      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: item.tags.map((final tag) {
          return Chip(label: Text('#$tag'));
        }).toList(),
      );
    }

    final createdAt = item.createdAt;
    final dateStr =
        '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} 加入';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer.withValues(
                    alpha: AppOpacity.overlay,
                  ),
                  foregroundColor: colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer.withValues(
                      alpha: AppOpacity.overlay,
                    ),
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: handleDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: imageFileAsync.when(
                data: (final file) => Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (final context, final error, final stackTrace) {
                    return Container(
                      color: colorScheme.surfaceContainerLow,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: AppSpacing.xxl,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                loading: () =>
                    Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                error: (final error, final stack) => Container(
                  color: colorScheme.surfaceContainerLow,
                  child: Center(
                    child: ErrorView(
                      isCompact: true,
                      onRetry: () =>
                          ref.refresh(wardrobeItemImageProvider(item.imagePath)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(item.category.displayName)),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '標籤',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  buildTagChips(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
