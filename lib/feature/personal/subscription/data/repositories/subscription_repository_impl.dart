import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_plan_info.dart';
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

    try {
      final remoteSubscription = await _remoteDataSource.getSubscription(userId);

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

  @override
  Future<Result<Subscription, Failure>> updateSubscription({
    required final String targetPlan,
  }) async {
    try {
      final remoteSubscription = await _remoteDataSource.updateSubscription(
        targetPlan: targetPlan,
      );

      try {
        await _localDataSource.saveSubscription(remoteSubscription);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to update subscription cache', e, stackTrace);
      }

      final subscription = _mappr.convert<SubscriptionModel, Subscription>(
        remoteSubscription,
      );
      return Ok(subscription);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update subscription', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SubscriptionPlanInfo>, Failure>> getSubscriptionPlans() async {
    try {
      final cachedPlans = await _localDataSource.getSubscriptionPlans();
      if (cachedPlans != null) {
        final subscriptionPlanInfos = cachedPlans
            .map(
              (final m) => _mappr.convert<SubscriptionPlanModel, SubscriptionPlanInfo>(m),
            )
            .toList();
        return Ok(subscriptionPlanInfos);
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Local plan cache read failed, falling back to remote',
        e,
        stackTrace,
      );
    }

    try {
      final remotePlans = await _remoteDataSource.getSubscriptionPlans();

      try {
        await _localDataSource.saveSubscriptionPlans(remotePlans);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save plans to cache', e, stackTrace);
      }

      final subscriptionPlanInfos = remotePlans
          .map(
            (final m) => _mappr.convert<SubscriptionPlanModel, SubscriptionPlanInfo>(m),
          )
          .toList();
      return Ok(subscriptionPlanInfos);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription plans', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
