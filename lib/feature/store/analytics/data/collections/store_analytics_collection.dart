import 'package:isar_community/isar.dart';

part 'store_analytics_collection.g.dart';

@collection
class StoreAnalyticsCollection {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('year'), CompositeIndex('month')])
  late String storeId;

  late int year;

  late int month;

  late int viewCount;

  late int tryonCount;

  late int purchaseClickCount;

  late DateTime updatedAt;
}
