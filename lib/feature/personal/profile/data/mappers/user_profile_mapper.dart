import 'package:tryzeon/core/shared/measurements/collections/body_measurements_collection.dart';
import '../collections/user_profile_collection.dart';
import '../models/user_profile_model.dart';

extension UserProfileModelMapper on UserProfileModel {
  UserProfileCollection toCollection() {
    return UserProfileCollection()
      ..userId = userId
      ..name = name
      ..avatarPath = avatarPath
      ..measurements = (BodyMeasurementsCollection()
        ..height = height
        ..chest = chest
        ..waist = waist
        ..hips = hips
        ..shoulder = shoulder
        ..sleeve = sleeve)
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension UserProfileCollectionMapper on UserProfileCollection {
  UserProfileModel toModel() {
    return UserProfileModel(
      userId: userId,
      name: name ?? '',
      height: measurements?.height,
      chest: measurements?.chest,
      waist: measurements?.waist,
      hips: measurements?.hips,
      shoulder: measurements?.shoulder,
      sleeve: measurements?.sleeve,
      avatarPath: avatarPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
