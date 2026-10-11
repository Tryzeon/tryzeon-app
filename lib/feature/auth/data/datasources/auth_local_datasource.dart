import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/auth/data/collections/auth_settings_cache.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<UserType?> getLastLoginType() async {
    final isar = await _isarService.db;
    final settings = await isar.authSettingsCaches.where().findFirst();
    return decodeCachedEnumOrNull(
      settings?.lastLoginType,
      UserType.tryFromString,
    );
  }

  Future<void> setLastLoginType(final UserType type) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final settings =
          await isar.authSettingsCaches.where().findFirst() ??
          AuthSettingsCache();
      settings.lastLoginType = type.value;
      await isar.authSettingsCaches.put(settings);
    });
  }
}
