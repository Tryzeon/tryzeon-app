import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/dtos/body_measurements_dto.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

part 'update_user_profile_request.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  createFactory: false,
  explicitToJson: true,
)
class UpdateUserProfileRequest {
  const UpdateUserProfileRequest({
    this.name,
    this.gender,
    this.ageRange,
    this.measurements,
    this.stylePreferences,
    this.isOnboarded,
    this.isTutorialCompleted,
  });

  final String? name;
  final Gender? gender;
  final AgeRange? ageRange;
  final BodyMeasurementsDto? measurements;
  final List<ClothingStyle>? stylePreferences;
  final bool? isOnboarded;
  final bool? isTutorialCompleted;

  Map<String, dynamic> toJson() => _$UpdateUserProfileRequestToJson(this);
}
