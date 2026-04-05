import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';

part 'tryon_params.freezed.dart';

@freezed
sealed class TryOnParams with _$TryOnParams {
  const factory TryOnParams({
    final String? avatarBase64,
    final String? avatarPath,
    final List<String>? clothesBase64s,
    final List<String>? clothesPaths,
    required final TryOnMode mode,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryOnParams;
}
