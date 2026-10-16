import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

part 'update_avatar_request.g.dart';

/// Always sends both columns: the row holds at most one avatar source, so
/// setting one must clear the other.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  createFactory: false,
)
class UpdateAvatarRequest {
  const UpdateAvatarRequest({
    required this.avatarPath,
    required this.avatarPreset,
  });

  final String? avatarPath;
  final PresetAvatar? avatarPreset;

  Map<String, dynamic> toJson() => _$UpdateAvatarRequestToJson(this);
}
