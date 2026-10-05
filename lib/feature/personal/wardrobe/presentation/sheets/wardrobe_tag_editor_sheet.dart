import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/loading_button.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/widgets/wardrobe_tag_input.dart';

class WardrobeTagEditorSheet extends HookWidget {
  const WardrobeTagEditorSheet({
    super.key,
    required this.initialTags,
    required this.onSave,
  });

  final List<String> initialTags;

  /// Resolves to an error message, or null once the tags are saved.
  final Future<String?> Function(List<String> tags) onSave;

  static Future<void> show({
    required final BuildContext context,
    required final List<String> initialTags,
    required final Future<String?> Function(List<String> tags) onSave,
  }) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) =>
          WardrobeTagEditorSheet(initialTags: initialTags, onSave: onSave),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tags = useState<List<String>>(List<String>.of(initialTags));
    final controller = useTextEditingController();
    final pending = useValueListenable(controller).text.trim();
    final isSaving = useState(false);

    final finalTags = pending.isEmpty || tags.value.contains(pending)
        ? tags.value
        : [...tags.value, pending];
    final hasChanges = !listEquals(finalTags, initialTags);

    void addTag() {
      tags.value = finalTags;
      controller.clear();
    }

    void removeTag(final int index) {
      tags.value = List<String>.of(tags.value)..removeAt(index);
    }

    Future<void> handleSave() async {
      isSaving.value = true;
      final errorMessage = await onSave(finalTags);
      if (!context.mounted) return;

      isSaving.value = false;
      if (errorMessage == null) {
        Navigator.of(context).pop();
        return;
      }
      TopNotification.show(context, message: errorMessage);
    }

    return AppSheet(
      title: '編輯標籤',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WardrobeTagInput(
              controller: controller,
              onAdd: addTag,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (tags.value.isEmpty)
              Text(
                '尚無標籤',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (index, tag) in tags.value.indexed)
                    Chip(
                      label: Text('#$tag'),
                      onDeleted: () => removeTag(index),
                    ),
                ],
              ),
          ],
        ),
      ),
      footer: LoadingButton.filled(
        isLoading: isSaving.value,
        onPressed: hasChanges ? handleSave : null,
        child: const Text('儲存'),
      ),
    );
  }
}
