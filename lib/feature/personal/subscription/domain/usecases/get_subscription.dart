import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetSubscription {
  GetSubscription({
    required final UserProfileRepository userProfileRepository,
    required final SubscriptionRepository subscriptionRepository,
  }) : _userProfileRepository = userProfileRepository,
       _subscriptionRepository = subscriptionRepository;

  final UserProfileRepository _userProfileRepository;
  final SubscriptionRepository _subscriptionRepository;

  Future<Result<Subscription, Failure>> call() async {
    // 1. Get user profile to extract userId
    final profileResult = await _userProfileRepository.getUserProfile();

    if (profileResult.isFailure) {
      return Err(profileResult.getError()!);
    }

    final profile = profileResult.get()!;

    // 2. Fetch subscription using userId
    return _subscriptionRepository.getSubscription(profile.userId);
  }
}
