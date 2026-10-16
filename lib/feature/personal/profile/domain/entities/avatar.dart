import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

part 'avatar.freezed.dart';

@freezed
sealed class Avatar with _$Avatar {
  const factory Avatar.preset(final PresetAvatar preset) = AvatarFromPreset;
  const factory Avatar.uploaded(final String path) = AvatarFromUpload;
}
