import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/collections/cache_schema.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_category/data/collections/product_category_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_cache.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';

class TestIsar {
  TestIsar(this.isar, this.service, this._dir);

  final Isar isar;
  final IsarService service;
  final Directory _dir;

  Future<void> dispose() async {
    await isar.close(deleteFromDisk: true);
    if (_dir.existsSync()) await _dir.delete(recursive: true);
  }
}

class _FixedIsarService extends IsarService {
  _FixedIsarService(this._isar);

  final Isar _isar;

  @override
  Future<Isar> openDB() async => _isar;
}

const _hostIsarCoreBinaries = {
  Abi.linuxX64: 'linux/libisar.so',
  Abi.macosArm64: 'macos/libisar.dylib',
  Abi.macosX64: 'macos/libisar.dylib',
  Abi.windowsX64: 'windows/libisar.dll',
};

// Not `download: true`: parallel test processes race writing one shared
// binary, and mapping it mid-write crashes the runner with SIGBUS.
Future<void> initializeTestIsarCore() async {
  final binary = _hostIsarCoreBinaries[Abi.current()];
  if (binary == null) {
    throw UnsupportedError('No IsarCore host binary for ${Abi.current()}');
  }
  final packages = await findPackageConfig(Directory.current);
  final flutterLibs = packages!['isar_community_flutter_libs']!.root;
  final path = flutterLibs.resolve(binary).toFilePath();
  await Isar.initializeIsarCore(libraries: {Abi.current(): path});
}

Future<TestIsar> openTestIsar() async {
  await initializeTestIsarCore();
  final dir = await Directory.systemTemp.createTemp('tryzeon_cache_test');
  final isar = await Isar.open(
    [
      CacheSchemaSchema,
      CacheEntrySchema,
      ProductCategoryCacheSchema,
      UserProfileCacheSchema,
      WardrobeItemCacheSchema,
      ProductCacheSchema,
      SubscriptionTierCacheSchema,
      StoreProfileCacheSchema,
      ProductAnalyticsCacheSchema,
    ],
    directory: dir.path,
    name: p.basename(dir.path),
    inspector: false,
  );

  return TestIsar(isar, _FixedIsarService(isar), dir);
}
