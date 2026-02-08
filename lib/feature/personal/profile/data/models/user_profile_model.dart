import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.name,
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
    this.avatarPath,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromEntity(final UserProfile entity) {
    return UserProfileModel(
      userId: entity.userId,
      name: entity.name,
      height: entity.measurements.height,
      chest: entity.measurements.chest,
      waist: entity.measurements.waist,
      hips: entity.measurements.hips,
      shoulder: entity.measurements.shoulder,
      sleeve: entity.measurements.sleeve,
      avatarPath: entity.avatarPath,
    );
  }

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  final String userId;
  final String name;
  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;
  final String? avatarPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  UserProfile toEntity() {
    return UserProfile(
      userId: userId,
      name: name,
      measurements: BodyMeasurements(
        height: height,
        chest: chest,
        waist: waist,
        hips: hips,
        shoulder: shoulder,
        sleeve: sleeve,
      ),
      avatarPath: avatarPath,
    );
  }
}
