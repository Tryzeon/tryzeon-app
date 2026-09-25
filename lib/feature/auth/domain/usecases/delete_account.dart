import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';
import 'package:typed_result/typed_result.dart';

class DeleteAccount {
  DeleteAccount({
    required final AuthRepository authRepository,
    required final AnalyticsEventQueue analyticsQueue,
    required final SignOut signOut,
  }) : _authRepository = authRepository,
       _analyticsQueue = analyticsQueue,
       _signOut = signOut;

  final AuthRepository _authRepository;
  final AnalyticsEventQueue _analyticsQueue;
  final SignOut _signOut;

  Future<Result<void, Failure>> call() async {
    try {
      await _analyticsQueue.forceFlush();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to flush analytics events (ignored)', e, stackTrace);
    }

    final deleted = await _authRepository.deleteAccount();
    if (deleted.isFailure) return deleted;

    final signedOut = await _signOut();
    if (signedOut.isFailure) {
      AppLogger.error('Sign-out after account deletion failed', signedOut.getError());
    }
    return const Ok(null);
  }
}
