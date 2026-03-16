import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';

class VideoPromptCustomizeSheet extends HookConsumerWidget {
  const VideoPromptCustomizeSheet({super.key});

  static const List<String> scenePresets = ['純白攝影棚', '都會街頭', '柔焦自然風景'];

  static const List<String> transitionPresets = ['一鏡到底', '動態跳剪', '柔和淡入淡出'];

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final context) => const VideoPromptCustomizeSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final configAsync = ref.watch(videoPromptConfigProvider);
    final config = configAsync.when(
      data: (final data) => data,
      loading: () => const VideoPromptConfig(),
      error: (_, final _) => const VideoPromptConfig(),
    );

    final sceneController = useTextEditingController(text: config.scenePrompt ?? '');
    final transitionController = useTextEditingController(
      text: config.transitionPrompt ?? '',
    );
    final isSaving = useState(false);

    // Sync controllers when config loads (only on first load)
    final hasInitialized = useRef(false);
    useEffect(() {
      if (!hasInitialized.value && configAsync.hasValue) {
        hasInitialized.value = true;
        configAsync.whenData((final loaded) {
          sceneController.text = loaded.scenePrompt ?? '';
          transitionController.text = loaded.transitionPrompt ?? '';
        });
      }
      return null;
    }, [configAsync.hasValue]);

    Future<void> handleSave() async {
      isSaving.value = true;
      final newConfig = VideoPromptConfig(
        scenePrompt: sceneController.text.trim().isEmpty
            ? null
            : sceneController.text.trim(),
        transitionPrompt: transitionController.text.trim().isEmpty
            ? null
            : transitionController.text.trim(),
      );
      await ref.read(videoPromptConfigProvider.notifier).save(newConfig);
      isSaving.value = false;
      if (context.mounted) Navigator.pop(context);
    }

    void appendChip(final TextEditingController controller, final String chip) {
      // 直接取代輸入框內容
      controller.text = chip;
      // Move cursor to end
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('自訂影片風格', style: textTheme.titleLarge),
                  ],
                ),
              ),

              // Scene Section
              Text('場景 Scene', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: scenePresets
                    .map(
                      (final preset) => ActionChip(
                        label: Text(preset),
                        onPressed: () => appendChip(sceneController, preset),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sceneController,
                decoration: InputDecoration(
                  hintText: '例如：純白攝影棚',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
                minLines: 1,
              ),

              const SizedBox(height: 20),

              // Transition Section
              Text('轉場 Transition', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: transitionPresets
                    .map(
                      (final preset) => ActionChip(
                        label: Text(preset),
                        onPressed: () => appendChip(transitionController, preset),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: transitionController,
                decoration: InputDecoration(
                  hintText: '例如：一鏡到底',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
                minLines: 1,
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSaving.value ? null : handleSave,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('儲存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
