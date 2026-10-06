import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:typed_result/typed_result.dart';

/// The settings view of the try-on sheet, navigated into rather than stacked
/// on top as a second sheet.
class TryonSettingsView extends HookConsumerWidget {
  const TryonSettingsView({
    super.key,
    required this.initial,
    required this.onBack,
  });

  final TryonPreferences initial;
  final VoidCallback onBack;

  static const List<String> stylingPresets = ['紮進褲頭', '衣襬放下', '袖子捲起'];

  static const List<String> scenePresets = ['純白攝影棚', '都會街頭', '柔焦自然風景'];

  static const List<String> transitionPresets = ['一鏡到底', '動態跳剪', '柔和淡入淡出'];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasVideoAccess = ref.watch(
      subscriptionCapabilitiesProvider.select(
        (final async) => async.value?.hasVideoAccess ?? false,
      ),
    );
    final stylingController = useTextEditingController(
      text: initial.stylingPrompt,
    );
    final sceneController = useTextEditingController(text: initial.scenePrompt);
    final transitionController = useTextEditingController(
      text: initial.transitionPrompt,
    );
    final engine = useState(initial.engine);
    final isSaving = useState(false);
    final promptsListenable = useMemoized(
      () => Listenable.merge([
        stylingController,
        sceneController,
        transitionController,
      ]),
    );

    String? promptOf(final TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    TryonPreferences buildDraft() => TryonPreferences(
      scenePrompt: promptOf(sceneController),
      stylingPrompt: promptOf(stylingController),
      transitionPrompt: promptOf(transitionController),
      engine: engine.value,
    );

    bool canSave() => !isSaving.value && buildDraft() != initial;

    Future<void> save() async {
      final draft = buildDraft();
      isSaving.value = true;
      final result = await ref
          .read(tryonPreferencesProvider.notifier)
          .save(draft);
      if (!context.mounted) return;
      isSaving.value = false;

      if (result.isFailure) {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
        return;
      }
      onBack();
    }

    Widget buildSectionLabel(final String title, {final String? scope}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: textTheme.titleSmall),
          if (scope != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              scope,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    Widget buildPromptField({
      required final TextEditingController controller,
      required final List<String> presets,
      required final String emptyLabel,
      required final String hint,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _PresetChips(
            controller: controller,
            presets: presets,
            emptyLabel: emptyLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            textInputAction: TextInputAction.done,
            maxLines: 2,
            minLines: 1,
          ),
        ],
      );
    }

    return AppSheet(
      title: '試穿設定',
      onBack: onBack,
      height: AppSheetHeight.tall,
      trailing: ListenableBuilder(
        listenable: promptsListenable,
        builder: (final context, final _) => TextButton(
          onPressed: canSave() ? save : null,
          child: const Text('儲存'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionLabel('穿搭細節'),
            buildPromptField(
              controller: stylingController,
              presets: stylingPresets,
              emptyLabel: '不指定',
              hint: '例如：外套敞開、袖口反摺',
            ),

            const SizedBox(height: AppSpacing.mdLg),

            buildSectionLabel('場景'),
            buildPromptField(
              controller: sceneController,
              presets: scenePresets,
              emptyLabel: '沿用原背景',
              hint: '例如：咖啡廳窗邊',
            ),

            // Transition only reaches the video generator.
            if (hasVideoAccess) ...[
              const SizedBox(height: AppSpacing.mdLg),
              buildSectionLabel('轉場', scope: '僅影片試穿'),
              buildPromptField(
                controller: transitionController,
                presets: transitionPresets,
                emptyLabel: '預設走秀',
                hint: '例如：緩慢環繞鏡頭',
              ),
            ],

            const SizedBox(height: AppSpacing.mdLg),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('實驗模型', style: textTheme.titleSmall),
              subtitle: Text(
                '改用評估中的其他模型生成，效果可能不穩定',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: engine.value == TryonEngine.experimental,
              onChanged: (final isExperimental) {
                engine.value = isExperimental
                    ? TryonEngine.experimental
                    : TryonEngine.standard;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Typing anything off-list surfaces a selected "自訂" chip, so exactly one chip
/// is always lit and an unlisted prompt never reads as "nothing applied".
/// [emptyLabel] differs per field: an empty scene keeps the original
/// background, an empty transition falls back to the default runway motion.
class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.controller,
    required this.presets,
    required this.emptyLabel,
  });

  final TextEditingController controller;
  final List<String> presets;
  final String emptyLabel;

  void _apply(final String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (final context, final value, final _) {
        final current = value.text.trim();
        final isCustom = current.isNotEmpty && !presets.contains(current);
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: Text(emptyLabel),
              selected: current.isEmpty,
              onSelected: (final _) => _apply(''),
            ),
            for (final preset in presets)
              ChoiceChip(
                label: Text(preset),
                selected: current == preset,
                onSelected: (final _) => _apply(preset),
              ),
            // Mirrors the field rather than setting it — re-picking the value
            // already typed is a no-op.
            if (isCustom)
              ChoiceChip(
                label: const Text('自訂'),
                selected: true,
                onSelected: (final _) {},
              ),
          ],
        );
      },
    );
  }
}
