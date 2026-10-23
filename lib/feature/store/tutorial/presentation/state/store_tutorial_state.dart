import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'store_tutorial_state.freezed.dart';

@freezed
sealed class StoreTutorialState with _$StoreTutorialState {
  const StoreTutorialState._();

  const factory StoreTutorialState.inactive() = StoreTutorialInactive;
  const factory StoreTutorialState.addProduct() = StoreTutorialAddProduct;
  const factory StoreTutorialState.pickImage() = StoreTutorialPickImage;
  const factory StoreTutorialState.analyzing() = StoreTutorialAnalyzing;
  const factory StoreTutorialState.reviewInfo() = StoreTutorialReviewInfo;
  const factory StoreTutorialState.price() = StoreTutorialPrice;
  const factory StoreTutorialState.purchaseLink() = StoreTutorialPurchaseLink;
  const factory StoreTutorialState.sizes() = StoreTutorialSizes;
  const factory StoreTutorialState.publish() = StoreTutorialPublish;
  const factory StoreTutorialState.save() = StoreTutorialSave;
  const factory StoreTutorialState.reviewProduct({
    required final ProductStatus status,
  }) = StoreTutorialReviewProduct;
  const factory StoreTutorialState.openAccount() = StoreTutorialOpenAccount;
  const factory StoreTutorialState.viewPerformance() =
      StoreTutorialViewPerformance;

  static const stepCount = 12;

  bool get isFormStep => switch (this) {
    StoreTutorialPickImage() ||
    StoreTutorialAnalyzing() ||
    StoreTutorialReviewInfo() ||
    StoreTutorialPrice() ||
    StoreTutorialPurchaseLink() ||
    StoreTutorialSizes() ||
    StoreTutorialPublish() ||
    StoreTutorialSave() => true,
    _ => false,
  };

  String? get stepLabel => switch (_stepNumber) {
    final step? => '$step / $stepCount',
    null => null,
  };

  int? get _stepNumber => switch (this) {
    StoreTutorialInactive() => null,
    StoreTutorialAddProduct() => 1,
    StoreTutorialPickImage() => 2,
    StoreTutorialAnalyzing() => 3,
    StoreTutorialReviewInfo() => 4,
    StoreTutorialPrice() => 5,
    StoreTutorialPurchaseLink() => 6,
    StoreTutorialSizes() => 7,
    StoreTutorialPublish() => 8,
    StoreTutorialSave() => 9,
    StoreTutorialReviewProduct() => 10,
    StoreTutorialOpenAccount() => 11,
    StoreTutorialViewPerformance() => 12,
  };
}
