import 'package:isar_community/isar.dart';

part 'cache_entry_collection.g.dart';

@collection
class CacheEntryCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheKey;

  late String status;

  @Index()
  late DateTime fetchedAt;
}
