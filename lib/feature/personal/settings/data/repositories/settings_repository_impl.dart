import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  @override
  Future<Result<bool, Failure>> getRecommendNearbyShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Ok(prefs.getBool(AppConstants.keyRecommendNearbyShops) ?? false);
    } catch (e, stackTrace) {
      AppLogger.error('無法讀取設定', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  @override
  Future<Result<void, Failure>> setRecommendNearbyShops(final bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyRecommendNearbyShops, value);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('無法儲存設定', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
