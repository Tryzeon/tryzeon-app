import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription.dart';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_category.dart';
import '../repositories/wardrobe_repository.dart';
import 'get_wardrobe_items.dart';

class UploadWardrobeItem {
  UploadWardrobeItem({
    required this.wardrobeRepository,
    required this.getSubscriptionUseCase,
    required this.getWardrobeItemsUseCase,
  });

  final WardrobeRepository wardrobeRepository;
  final GetSubscription getSubscriptionUseCase;
  final GetWardrobeItems getWardrobeItemsUseCase;

  Future<Result<void, Failure>> call({
    required final File image,
    required final WardrobeCategory category,
    final List<String> tags = const [],
  }) async {
    final subscriptionResult = await getSubscriptionUseCase();
    if (subscriptionResult.isFailure) {
      return Err(subscriptionResult.getError()!);
    }
    final subscription = subscriptionResult.get()!;

    final wardrobeItemsResult = await getWardrobeItemsUseCase();
    if (wardrobeItemsResult.isFailure) {
      return Err(wardrobeItemsResult.getError()!);
    }
    final wardrobeItems = wardrobeItemsResult.get()!;

    if (wardrobeItems.length >= subscription.plan.wardrobeLimit) {
      return const Err(ValidationFailure());
    }

    return wardrobeRepository.uploadWardrobeItem(
      image: image,
      category: category,
      tags: tags,
    );
  }
}
