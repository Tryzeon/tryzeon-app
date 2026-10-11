import 'package:tryzeon/core/domain/services/local_data_store.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Only the Supabase sign-out decides the result; every local teardown step
/// still runs, and a failed one is logged rather than returned.
class SignOut {
  SignOut({
    required final AuthRepository authRepository,
    required final AnalyticsEventQueue analyticsQueue,
    required final LocalDataStore localDataStore,
    required final SettingsRepository settingsRepository,
  }) : _authRepository = authRepository,
       _analyticsQueue = analyticsQueue,
       _localDataStore = localDataStore,
       _settingsRepository = settingsRepository;

  final AuthRepository _authRepository;
  final AnalyticsEventQueue _analyticsQueue;
  final LocalDataStore _localDataStore;
  final SettingsRepository _settingsRepository;

  Future<Result<void, Failure>> call() async {
    _logIgnored('flush analytics events', await _analyticsQueue.forceFlush());

    final signedOut = await _authRepository.signOut();

    _logIgnored('clear local data', await _localDataStore.clear());
    _logIgnored(
      'clear device preferences',
      await _settingsRepository.clearTryonPreferences(),
    );

    return signedOut;
  }

  void _logIgnored(final String step, final Result<void, Failure> result) {
    if (result.isFailure) {
      AppLogger.error('Failed to $step (ignored)', result.getError());
    }
  }
}
