import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/dtos/body_measurements_dto.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

part 'user_profile_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.measurements,
    this.avatarPath,
    this.gender,
    this.ageRange,
    this.stylePreferences,
    this.isOnboarded = false,
  });

  factory UserProfileDto.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final BodyMeasurementsDto? measurements;
  final String? avatarPath;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final Gender? gender;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final AgeRange? ageRange;
  @JsonKey(fromJson: _stylePreferencesFromJson)
  final List<ClothingStyle>? stylePreferences;
  @JsonKey(defaultValue: false)
  final bool isOnboarded;

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}

List<ClothingStyle>? _stylePreferencesFromJson(final List<dynamic>? json) =>
    ClothingStyle.listFromStrings(json?.whereType<String>());
