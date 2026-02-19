import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart';

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

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  final String userId;
  final String name;
  final String? email;
  final MeasurementsModel? measurements;
  final String? avatarPath;
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);
}
