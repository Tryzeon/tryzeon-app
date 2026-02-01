import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';
import 'package:typed_result/typed_result.dart';

abstract class SubscriptionRepository {
  Future<Result<Subscription, Failure>> getSubscription(final String userId);
}
