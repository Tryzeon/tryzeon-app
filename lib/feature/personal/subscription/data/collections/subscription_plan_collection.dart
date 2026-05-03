import 'package:isar_community/isar.dart';

part 'subscription_plan_collection.g.dart';

@collection
class SubscriptionPlanCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String planId;

  late String name;
  late int price;
  late int wardrobeLimit;
  late int tryonLimit;
  late int videoLimit;
  late int chatLimit;
  late int sortOrder;
  late bool isActive;
}
