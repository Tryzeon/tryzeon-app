import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';

part 'tryon_params.freezed.dart';

@freezed
sealed class TryOnParams with _$TryOnParams {
  const factory TryOnParams({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
    required final TryOnMode mode,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryOnParams;
}
