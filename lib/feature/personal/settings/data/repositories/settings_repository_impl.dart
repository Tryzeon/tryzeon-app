import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/own_photo_invite_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/tryon_preferences_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._tryonPreferences, this._ownPhotoInvite);

  final TryonPreferencesLocalDataSource _tryonPreferences;
  final OwnPhotoInviteLocalDataSource _ownPhotoInvite;

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
  Future<Result<bool, Failure>> isOwnPhotoInviteDismissed() async {
    try {
      return Ok(await _ownPhotoInvite.isDismissed());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read own-photo invite state', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> dismissOwnPhotoInvite() async {
    try {
      await _ownPhotoInvite.dismiss();
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to dismiss own-photo invite', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  /// Every preference is cleared even when one fails, so a broken key never
  /// leaves the previous user's choices behind.
  @override
  Future<Result<void, Failure>> clearDevicePreferences() async {
    Failure? failure;

    try {
      await _tryonPreferences.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear tryon preferences', e, stackTrace);
      failure = mapExceptionToFailure(e);
    }

    try {
      await _ownPhotoInvite.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear own-photo invite state', e, stackTrace);
      failure ??= mapExceptionToFailure(e);
    }

    return failure == null ? const Ok(null) : Err(failure);
  }
}
