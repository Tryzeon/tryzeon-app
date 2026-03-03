import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateSubscription {
  UpdateSubscription({
    required final UserProfileRepository userProfileRepository,
    required final SubscriptionRepository subscriptionRepository,
  }) : _userProfileRepository = userProfileRepository,
       _subscriptionRepository = subscriptionRepository;

  final UserProfileRepository _userProfileRepository;
  final SubscriptionRepository _subscriptionRepository;

  Future<Result<Subscription, Failure>> call({
    required final SubscriptionPlan targetPlan,
  }) async {
    final profileResult = await _userProfileRepository.getUserProfile();

    if (profileResult.isFailure) {
      return Err(profileResult.getError()!);
    }

    return _subscriptionRepository.updateSubscription(targetPlan: targetPlan);
  }
}
