import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription_capabilities.dart';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';
import 'get_wardrobe_items.dart';

class UploadWardrobeItem {
  UploadWardrobeItem({
    required this.wardrobeRepository,
    required this.getSubscriptionCapabilitiesUseCase,
    required this.getWardrobeItemsUseCase,
  });

  final WardrobeRepository wardrobeRepository;
  final GetSubscriptionCapabilities getSubscriptionCapabilitiesUseCase;
  final GetWardrobeItems getWardrobeItemsUseCase;

  Future<Result<void, Failure>> call(final CreateWardrobeItemParams params) async {
    final capabilitiesResult = await getSubscriptionCapabilitiesUseCase();
    if (capabilitiesResult.isFailure) {
      return Err(capabilitiesResult.getError()!);
    }
    final capabilities = capabilitiesResult.get()!;

    final wardrobeItemsResult = await getWardrobeItemsUseCase();
    if (wardrobeItemsResult.isFailure) {
      return Err(wardrobeItemsResult.getError()!);
    }
    final wardrobeItems = wardrobeItemsResult.get()!;

    if (wardrobeItems.length >= capabilities.wardrobeLimit) {
      return const Err(ValidationFailure());
    }

    return wardrobeRepository.uploadWardrobeItem(params);
  }
}
