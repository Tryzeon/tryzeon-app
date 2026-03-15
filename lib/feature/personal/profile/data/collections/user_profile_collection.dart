import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/shared/measurements/collections/measurements_collection.dart';

part 'user_profile_collection.g.dart';

@collection
class UserProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String name;
  String? email;
  String? avatarPath;

  MeasurementsCollection? measurements;

  String? gender;
  String? ageRange;
  List<String>? stylePreferences;
  late bool isOnboarded;

  DateTime? lastUpdated;
}
