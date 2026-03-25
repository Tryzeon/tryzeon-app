import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription_plans.dart';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';
import 'get_wardrobe_items.dart';

class UploadWardrobeItem {
  UploadWardrobeItem({
    required this.wardrobeRepository,
    required this.getSubscriptionUseCase,
    required this.getSubscriptionPlansUseCase,
    required this.getWardrobeItemsUseCase,
  });

  final WardrobeRepository wardrobeRepository;
  final GetSubscription getSubscriptionUseCase;
  final GetSubscriptionPlans getSubscriptionPlansUseCase;
  final GetWardrobeItems getWardrobeItemsUseCase;

  Future<Result<void, Failure>> call(final CreateWardrobeItemParams params) async {
    final subscriptionResult = await getSubscriptionUseCase();
    if (subscriptionResult.isFailure) {
      return Err(subscriptionResult.getError()!);
    }
    final subscription = subscriptionResult.get()!;

    final plansResult = await getSubscriptionPlansUseCase();
    if (plansResult.isFailure) {
      return Err(plansResult.getError()!);
    }
    final plans = plansResult.get()!;
    final currentPlanInfoList = plans
        .where((final p) => p.id == subscription.plan)
        .toList();
    if (currentPlanInfoList.isEmpty) {
      return const Err(UnknownFailure());
    }

    final wardrobeItemsResult = await getWardrobeItemsUseCase();
    if (wardrobeItemsResult.isFailure) {
      return Err(wardrobeItemsResult.getError()!);
    }
    final wardrobeItems = wardrobeItemsResult.get()!;

    if (wardrobeItems.length >= currentPlanInfoList.first.wardrobeLimit) {
      return const Err(ValidationFailure());
    }

    return wardrobeRepository.uploadWardrobeItem(params);
  }
}
