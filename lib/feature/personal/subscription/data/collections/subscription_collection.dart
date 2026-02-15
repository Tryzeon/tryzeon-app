import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';

part 'subscription_collection.g.dart';

@collection
class SubscriptionCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  @Enumerated(EnumType.name)
  late SubscriptionPlan plan;

  DateTime? lastUpdated;
}
