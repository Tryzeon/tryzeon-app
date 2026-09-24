import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/models/body_measurements_model.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfileModel {
  const UserProfileModel({
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

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final BodyMeasurementsModel? measurements;
  final String? avatarPath;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final Gender? gender;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final AgeRange? ageRange;
  @JsonKey(fromJson: _stylePreferencesFromJson)
  final List<ClothingStyle>? stylePreferences;
  @JsonKey(defaultValue: false)
  final bool isOnboarded;

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);
}

List<ClothingStyle>? _stylePreferencesFromJson(final List<dynamic>? json) =>
    ClothingStyle.listFromStrings(json?.whereType<String>());
