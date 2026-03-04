import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_plan_info.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetSubscriptionPlans {
  GetSubscriptionPlans({required final SubscriptionRepository subscriptionRepository})
    : _subscriptionRepository = subscriptionRepository;

  final SubscriptionRepository _subscriptionRepository;

  Future<Result<List<SubscriptionPlanInfo>, Failure>> call() {
    return _subscriptionRepository.getSubscriptionPlans();
  }
}
