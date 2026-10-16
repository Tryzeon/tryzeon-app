import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';

class ModelChoiceSheet extends ConsumerWidget {
  const ModelChoiceSheet({
    super.key,
    required this.current,
    required this.onPresetSelected,
    required this.onUploadOwnPhoto,
  });

  final PresetAvatar? current;
  final ValueChanged<PresetAvatar> onPresetSelected;
  final VoidCallback onUploadOwnPhoto;

  static Future<void> show({
    required final BuildContext context,
    required final PresetAvatar? current,
    required final ValueChanged<PresetAvatar> onPresetSelected,
    required final VoidCallback onUploadOwnPhoto,
  }) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => ModelChoiceSheet(
        current: current,
        onPresetSelected: onPresetSelected,
        onUploadOwnPhoto: onUploadOwnPhoto,
      ),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final gender = ref.watch(
      userProfileProvider.select((final async) => async.value?.gender),
    );

    void selectPreset(final PresetAvatar preset) {
      Navigator.of(context).pop();
      if (preset != current) onPresetSelected(preset);
    }

    // Popped before the callback: the photo-source sheet it opens would
    // otherwise be the route this pop removes.
    void uploadOwnPhoto() {
      Navigator.of(context).pop();
      onUploadOwnPhoto();
    }

    return AppSheet(
      title: '更換模特',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: ModelChoicePicker(
            presets: PresetAvatar.forGender(gender),
            selected: current,
            onPresetSelected: selectPreset,
            onUploadOwnPhoto: uploadOwnPhoto,
          ),
        ),
      ),
    );
  }
}
