import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/shells/store_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';

/// Sits in the root overlay just above the shell page, so the add-product
/// page and any sheet pushed later cover these hints.
class StoreTutorialOverlay extends HookConsumerWidget {
  const StoreTutorialOverlay({
    super.key,
    required this.currentTab,
    required this.child,
  });

  static const addProductMessage = '歡迎加入 Tryzeon！從這裡上架你的第一件商品';
  static const reviewActiveProductMessage =
      '上架完成！顧客現在就能在試衣間試穿它。卡片下方是這件商品的瀏覽、試穿和購買點擊，點商品可以編輯或下架';
  static const reviewArchivedProductMessage =
      '已儲存但還沒上架，顧客暫時看不到；想上架時點卡片右下角的「⋯」選「重新上架」。卡片下方是這件商品的瀏覽、試穿和購買點擊';

  static String reviewProductMessage(final ProductStatus status) =>
      switch (status) {
        ProductStatus.active => reviewActiveProductMessage,
        ProductStatus.archived => reviewArchivedProductMessage,
      };
  static const accountTabMessage = '點下方的「我的」，看整間店的成效總覽';
  static const performanceMessage = '這裡是整間店每個月的試穿、瀏覽和購買點擊，右上角可以切換月份';

  final StoreTab currentTab;
  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final portal = useMemoized(() => OverlayPortalController()..show());
    final tutorial = ref.watch(storeTutorialControllerProvider);
    final controller = ref.read(storeTutorialControllerProvider.notifier);
    final onAccountTab = currentTab == StoreTab.account;
    final awaitsAccountTab = tutorial is StoreTutorialOpenAccount;

    // Riverpod forbids provider writes while the tree builds.
    useEffect(() {
      if (awaitsAccountTab && onAccountTab) {
        unawaited(Future.microtask(controller.accountTabOpened));
      }
      return null;
    }, [awaitsAccountTab, onAccountTab]);

    final addProductFab = onAccountTab
        ? CoachMarkTarget.storeAccountAddFab
        : CoachMarkTarget.storeProductsAddFab;
    final Widget? hint = switch (tutorial) {
      StoreTutorialAddProduct() => CoachMarkHint(
        key: ValueKey(addProductFab),
        target: addProductFab,
        message: addProductMessage,
        placement: CoachMarkPlacement.above,
        onSkip: controller.finish,
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialReviewProduct(:final status) => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.storeFirstProductStats),
        target: CoachMarkTarget.storeFirstProductStats,
        targetGap: AppSpacing.xs,
        message: reviewProductMessage(status),
        placement: CoachMarkPlacement.above,
        onSkip: controller.finish,
        action: (label: CoachMarkHint.nextLabel, onPressed: controller.next),
        stepLabel: tutorial.stepLabel,
      ),
      StoreTutorialOpenAccount() => CoachMarkChromeHint(
        message: accountTabMessage,
        stepLabel: tutorial.stepLabel,
        onSkip: controller.finish,
      ),
      StoreTutorialViewPerformance() => CoachMarkHint(
        key: const ValueKey(CoachMarkTarget.storePerformance),
        target: CoachMarkTarget.storePerformance,
        targetRadius: const Radius.circular(AppRadius.card),
        message: performanceMessage,
        placement: CoachMarkPlacement.below,
        action: (label: CoachMarkHint.doneLabel, onPressed: controller.finish),
        revealTarget: true,
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
