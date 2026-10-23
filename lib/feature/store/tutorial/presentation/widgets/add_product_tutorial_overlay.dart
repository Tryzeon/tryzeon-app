import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';

/// The add-product page is a full-screen route that covers the shell overlay,
/// so its steps get their own portal, which the sheets it pushes cover in turn.
class AddProductTutorialOverlay extends HookConsumerWidget {
  const AddProductTutorialOverlay({super.key, required this.child});

  static const pickImageMessage = '先放一張商品的完整正面照當主圖，顧客試穿用的就是這張';
  static const analyzingMessage = 'AI 會自動分析版型、風格等描述…';
  static const reviewMessage = 'AI 已經幫你填好名稱、性別、分類，以及進階資料的屬性，檢查一下有沒有錯';
  static const priceMessage = '填上售價，顧客在試衣間看到的就是這個價格';
  static const purchaseLinkMessage =
      '貼上商品購買連結，顧客試穿完就能直接購買；沒有購買連結的話，可以在「設定 → 店家資料」設定聯絡方式，讓顧客私訊你下單';
  static const sizesMessage = '尺寸可以自行填入也可以用說的：按下麥克風，念出每個尺寸的量測數字就能幫你填進表格';
  static const saveMessage = '都確認好了就按儲存，商品會馬上上架';

  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final portal = useMemoized(() => OverlayPortalController()..show());
    final tutorial = ref.watch(storeTutorialControllerProvider);
    final controller = ref.read(storeTutorialControllerProvider.notifier);

    // Riverpod forbids provider writes while the tree builds or unmounts.
    useEffect(() {
      unawaited(Future.microtask(controller.enterAddProduct));
      return () => unawaited(Future.microtask(controller.leaveAddProduct));
    }, const []);

    final next = (label: CoachMarkHint.nextLabel, onPressed: controller.next);
    final Widget? hint = switch (tutorial) {
      StoreTutorialPickImage() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productImages),
        target: CoachMarkTarget.productImages,
        message: pickImageMessage,
        targetRadius: const Radius.circular(AppRadius.button),
        onSkip: controller.finish,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialAnalyzing() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productImageAnalyzing),
        target: CoachMarkTarget.productImageAnalyzing,
        targetGap: AppSpacing.sm,
        message: analyzingMessage,
        onSkip: controller.finish,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialReviewInfo() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productName),
        target: CoachMarkTarget.productName,
        targetRadius: const Radius.circular(AppRadius.input),
        placement: CoachMarkPlacement.above,
        message: reviewMessage,
        onSkip: controller.finish,
        action: next,
        revealTarget: true,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialPrice() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productPrice),
        target: CoachMarkTarget.productPrice,
        targetRadius: const Radius.circular(AppRadius.input),
        message: priceMessage,
        placement: CoachMarkPlacement.above,
        onSkip: controller.finish,
        action: next,
        revealTarget: true,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialPurchaseLink() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productPurchaseLink),
        target: CoachMarkTarget.productPurchaseLink,
        targetRadius: const Radius.circular(AppRadius.input),
        message: purchaseLinkMessage,
        placement: CoachMarkPlacement.above,
        onSkip: controller.finish,
        action: next,
        revealTarget: true,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialSizes() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productSizeVoice),
        target: CoachMarkTarget.productSizeVoice,
        placement: CoachMarkPlacement.above,
        message: sizesMessage,
        onSkip: controller.finish,
        action: next,
        revealTarget: true,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialSave() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.productSave),
        target: CoachMarkTarget.productSave,
        message: saveMessage,
        onSkip: controller.finish,
        stepLabel: tutorial.stepLabel,
      ),
      _ => null,
    };

    return OverlayPortal(
      controller: portal,
      overlayChildBuilder: (final _) => Stack(children: [?hint]),
      child: child,
    );
  }
}
