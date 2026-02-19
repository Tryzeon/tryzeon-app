import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required final SubscriptionRemoteDataSource remoteDataSource,
    required final SubscriptionLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<Subscription, Failure>> getSubscription(
    final String userId, {
    final bool forceRefresh = false,
  }) async {
    // 1. Try Local Cache
    if (!forceRefresh) {
      try {
        final cachedSubscription = await _localDataSource.getSubscription(userId);
        if (cachedSubscription != null) {
          final subscription = _mappr.convert<SubscriptionModel, Subscription>(
            cachedSubscription,
          );
          return Ok(subscription);
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }
    }

    // 2. Fetch from API
    try {
      final remoteSubscription = await _remoteDataSource.getSubscription(userId);

      // 3. Update Cache
      try {
        await _localDataSource.saveSubscription(remoteSubscription);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save subscription to cache', e, stackTrace);
      }

      final subscription = _mappr.convert<SubscriptionModel, Subscription>(
        remoteSubscription,
      );
      return Ok(subscription);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription data', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
