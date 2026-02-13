import 'package:tryzeon/core/shared/measurements/data/models/body_measurements_model.dart';

import '../collections/user_profile_collection.dart';
import '../models/user_profile_model.dart';

extension UserProfileModelMapper on UserProfileModel {
  UserProfileCollection toCollection() {
    return UserProfileCollection()
      ..userId = userId
      ..name = name
      ..email = email
      ..avatarPath = avatarPath
      ..measurements = measurements?.toCollection();
  }
}

extension UserProfileCollectionMapper on UserProfileCollection {
  UserProfileModel toModel() {
    return UserProfileModel(
      userId: userId,
      name: name ?? '',
      email: email,
      measurements: measurements != null
          ? BodyMeasurementsModel.fromCollection(measurements!)
          : null,
      avatarPath: avatarPath,
    );
  }
}
