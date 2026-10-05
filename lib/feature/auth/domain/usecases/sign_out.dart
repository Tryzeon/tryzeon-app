import 'package:tryzeon/core/domain/services/image_file_cache.dart';
import 'package:tryzeon/core/domain/services/local_database.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SignOut {
  SignOut({
    required final AuthRepository authRepository,
    required final AnalyticsEventQueue analyticsQueue,
    required final ImageFileCache imageFileCache,
    required final LocalDatabase localDatabase,
    required final SettingsRepository settingsRepository,
  }) : _authRepository = authRepository,
       _analyticsQueue = analyticsQueue,
       _imageFileCache = imageFileCache,
       _localDatabase = localDatabase,
       _settingsRepository = settingsRepository;

  final AuthRepository _authRepository;
  final AnalyticsEventQueue _analyticsQueue;
  final ImageFileCache _imageFileCache;
  final LocalDatabase _localDatabase;
  final SettingsRepository _settingsRepository;

  Future<Result<void, Failure>> call() async {
    try {
      await _analyticsQueue.forceFlush();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to flush analytics events (ignored)',
        e,
        stackTrace,
      );
    }

    final signedOut = await _authRepository.signOut();

    try {
      await _imageFileCache.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache (ignored)', e, stackTrace);
    }

    try {
      await _localDatabase.clear();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear local database (ignored)',
        e,
        stackTrace,
      );
    }

    final preferencesCleared = await _settingsRepository
        .clearTryonPreferences();
    if (preferencesCleared.isFailure) {
      AppLogger.error(
        'Failed to clear device preferences (ignored)',
        preferencesCleared.getError(),
      );
    }

    return signedOut;
  }
}
