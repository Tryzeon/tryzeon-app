import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_prompt_config.freezed.dart';

@freezed
sealed class VideoPromptConfig with _$VideoPromptConfig {
  const factory VideoPromptConfig({
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _VideoPromptConfig;
  const VideoPromptConfig._();

  /// Whether user has customized any prompt field.
  bool get hasCustomization =>
      (scenePrompt != null && scenePrompt!.isNotEmpty) ||
      (transitionPrompt != null && transitionPrompt!.isNotEmpty);

  /// Returns a new config with both fields cleared.
  static const empty = VideoPromptConfig();
}
