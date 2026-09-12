import 'package:isar_community/isar.dart';

part 'cache_schema.g.dart';

@collection
class CacheSchema {
  Id id = 0;

  late int version;
}
