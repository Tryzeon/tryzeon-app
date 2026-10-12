import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/tryon_preferences_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._tryonPreferences);

  final TryonPreferencesLocalDataSource _tryonPreferences;

  @override
  Future<Result<TryonPreferences, Failure>> getTryonPreferences() async {
    try {
      return Ok(await _tryonPreferences.read());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read tryon preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> setTryonPreferences(
    final TryonPreferences preferences,
  ) async {
    try {
      await _tryonPreferences.write(preferences);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save tryon preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> clearTryonPreferences() async {
    try {
      await _tryonPreferences.clear();
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear tryon preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
