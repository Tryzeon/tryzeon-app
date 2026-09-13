import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/loading_button.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

class UploadWardrobeItemSheet extends HookConsumerWidget {
  const UploadWardrobeItemSheet({super.key, required this.image});
  final File image;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selectedGarmentType = useState<GarmentType?>(null);
    final isUploading = ref.watch(wardrobeEditProvider).isLoading;
    final tags = useState<List<String>>(const []);
    final tagController = useTextEditingController();
    final removedBgImage = useState<Uint8List?>(null);
    final useRemovedBg = useState(true);
    final isAnalyzingTags = useState(true);

    useEffect(() {
      var cancelled = false;
      final usecase = ref.read(analyzeWardrobeImageUseCaseProvider);

      Future<void> runBackground() async {
        final bg = await usecase.removeBackground(image);
        if (!cancelled) removedBgImage.value = bg;
      }

      Future<void> runLabels() async {
        final result = await usecase.labels(image);
        if (cancelled) return;
        tags.value = result.tags;
        if (result.garmentType != null && selectedGarmentType.value == null) {
          selectedGarmentType.value = result.garmentType;
        }
        isAnalyzingTags.value = false;
      }

      runBackground();
      runLabels();
      return () => cancelled = true;
    }, const []);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void addTag() {
      final text = tagController.text.trim();
      if (text.isEmpty) return;
      if (!tags.value.contains(text)) {
        tags.value = [...tags.value, text];
      }
      tagController.clear();
    }

    void removeTag(final int index) {
      tags.value = List<String>.of(tags.value)..removeAt(index);
    }

    Future<void> handleUpload() async {
      final pendingTag = tagController.text.trim();
      if (pendingTag.isNotEmpty) addTag();

      final result = await ref
          .read(wardrobeEditProvider.notifier)
          .upload(
            image: image,
            garmentType: selectedGarmentType.value!,
            tags: tags.value,
            replacementBytes: useRemovedBg.value ? removedBgImage.value : null,
          );

      if (!context.mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context, selectedGarmentType.value);
      } else {
        final failure = result.getError()!;

        if (failure is ValidationFailure) {
          UpgradeDialog.show(
            context,
            title: '衣櫃已達上限',
            content: '您的衣櫃容量已達上限\n升級至更高方案以獲得更多儲存空間！',
          );
        } else {
          TopNotification.show(context, message: failure.displayMessage(context));
        }
      }
    }

    Widget buildCapacityIndicator() {
      final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
      final itemsAsync = ref.watch(wardrobeItemsProvider);

      return switch ((capabilitiesAsync, itemsAsync)) {
        (AsyncData(value: final capabilities), AsyncData(value: final items)) => () {
          final limit = capabilities.wardrobeLimit;
          final current = items.length;
          final percentage = current / limit;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '衣櫃容量',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$current / $limit 件',
                    style: textTheme.labelMedium?.copyWith(
                      color: percentage >= 0.9 ? colorScheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.buttonAll,
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: percentage >= 0.9 ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
            ],
          );
        }(),
        _ => const SizedBox.shrink(),
      };
    }

    Widget buildImagePreviewRow() {
      return Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: useRemovedBg.value && removedBgImage.value != null
                ? Image.memory(
                    removedBgImage.value!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: buildCapacityIndicator()),
        ],
      );
    }

    Widget buildBackgroundToggle() {
      if (removedBgImage.value == null) return const SizedBox.shrink();
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('自動去背', style: textTheme.labelLarge),
        value: useRemovedBg.value,
        onChanged: (final v) => useRemovedBg.value = v,
      );
    }

    Widget buildCategorySelector() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇類別 *',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: GarmentType.values.map((final garmentType) {
              final isSelected = selectedGarmentType.value == garmentType;

              return ChoiceChip(
                label: Text(garmentType.displayName),
                selected: isSelected,
                onSelected: (final selected) => selectedGarmentType.value = garmentType,
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget buildTagEditor() {
      if (isAnalyzingTags.value) {
        return Row(
          children: [
            const SizedBox(
              width: AppSpacing.md,
              height: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '分析中…',
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: tagController,
            textInputAction: TextInputAction.done,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '新增標籤...',
              suffixIcon: GestureDetector(
                onTap: addTag,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.add_rounded, color: colorScheme.onSurfaceVariant),
              ),
            ),
            onSubmitted: (final _) => addTag(),
          ),
          if (tags.value.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in tags.value.asMap().entries)
                  Chip(
                    label: Text('#${entry.value}'.toUpperCase()),
                    onDeleted: () => removeTag(entry.key),
                  ),
              ],
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text('上傳衣服', style: textTheme.titleMedium),
        ),
        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildImagePreviewRow(),
                if (removedBgImage.value != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  buildBackgroundToggle(),
                ],
                const SizedBox(height: AppSpacing.lg),
                buildCategorySelector(),
                const SizedBox(height: AppSpacing.lg),
                buildTagEditor(),
              ],
            ),
          ),
        ),
        // Footer
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          child: LoadingButton.filled(
            isLoading: isUploading,
            onPressed: selectedGarmentType.value != null && !isAnalyzingTags.value
                ? handleUpload
                : null,
            child: const Text('上傳'),
          ),
        ),
      ],
    );
  }
}
