import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/collections/cache_schema.dart';

/// Isar migrates collection schemas automatically but keeps the rows, so a
/// field added or renamed by a release leaves old rows decoding to defaults
/// while their CacheEntry still says the cache is valid. Bumping
/// [AppConstants.cacheSchemaVersion] wipes every collection once, before any
/// repository reads, so no per-release list of affected caches is needed —
/// every cache is refetchable.
///
/// A renamed enum value needs no bump: `decodeCachedEnum` rejects the stale
/// string and the repository refetches that row on its own. The wipe is the
/// only remedy for changes no decoder can detect, and it costs every user
/// their cached auth settings too.
class CacheMigrator {
  CacheMigrator._();

  static Future<void> run(final Isar isar) async {
    final stored = (await isar.cacheSchemas.get(0))?.version;
    if (stored != null && stored >= AppConstants.cacheSchemaVersion) return;

    await isar.writeTxn(() async {
      await isar.clear();
      await isar.cacheSchemas.put(
        CacheSchema()
          ..id = 0
          ..version = AppConstants.cacheSchemaVersion,
      );
    });
  }
}
