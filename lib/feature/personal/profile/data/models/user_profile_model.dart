import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/body_measurements_model.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.name,
    this.email,
    this.measurements,
    this.avatarPath,
  });

  factory UserProfileModel.fromEntity(final UserProfile entity) {
    return UserProfileModel(
      userId: entity.userId,
      name: entity.name,
      email: entity.email,
      measurements: BodyMeasurementsModel.fromEntity(entity.measurements),
      avatarPath: entity.avatarPath,
    );
  }

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  final String userId;
  final String name;
  final String? email;
  final BodyMeasurementsModel? measurements;
  final String? avatarPath;
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  UserProfile toEntity() {
    return UserProfile(
      userId: userId,
      name: name,
      email: email,
      measurements: measurements?.toEntity() ?? const BodyMeasurements(),
      avatarPath: avatarPath,
    );
  }
}
