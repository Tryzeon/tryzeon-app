import 'package:isar_community/isar.dart';

part 'subscription_collection.g.dart';

@collection
class SubscriptionCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String plan;

  DateTime? lastUpdated;
}
