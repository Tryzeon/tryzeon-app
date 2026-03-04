import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateSubscription {
  UpdateSubscription({required final SubscriptionRepository subscriptionRepository})
    : _subscriptionRepository = subscriptionRepository;

  final SubscriptionRepository _subscriptionRepository;

  Future<Result<Subscription, Failure>> call({required final String targetPlan}) async {
    return _subscriptionRepository.updateSubscription(targetPlan: targetPlan);
  }
}
