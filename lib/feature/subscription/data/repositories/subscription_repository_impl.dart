import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._remoteDataSource);

  final SubscriptionRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Subscription, Failure>> getSubscription(final String userId) async {
    try {
      final subscription = await _remoteDataSource.getSubscription(userId);
      return Ok(subscription.toEntity());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription data', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
