import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';

/// Sits in the root overlay just above the shell page, so routes pushed later
/// (the try-on mode sheet, dialogs, full-screen pages) cover the hints.
class TutorialOverlay extends HookConsumerWidget {
  const TutorialOverlay({
    super.key,
    required this.currentTab,
    required this.child,
  });

  static const shopTabMessage = '模特準備好了！點下方「試衣間」挑一件衣服試穿看看';
  static const tapTryonMessage = '點「試穿」，看看穿在模特身上的樣子';
  static const reviewMessage = '完成第一次試穿！左右滑動切換結果，喜歡就按讚';

  final PersonalTab currentTab;
  final Widget child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final portal = useMemoized(() => OverlayPortalController()..show());
    final tutorial = ref.watch(tutorialControllerProvider);
    final currentEntryId = ref.watch(
      tryonGalleryProvider.select((final s) => s.currentId),
    );
    final controller = ref.read(tutorialControllerProvider.notifier);

    final List<Widget> hints = switch (tutorial) {
      TutorialStartTryon() => [
        if (currentTab != PersonalTab.shop)
          CoachMarkChromeHint(
            message: shopTabMessage,
            stepLabel: '1 / 3',
            onSkip: controller.complete,
          ),
        CoachMarkHint(
          key: const ValueKey(CoachMarkTarget.firstProductTryon),
          target: CoachMarkTarget.firstProductTryon,
          message: tapTryonMessage,
          placement: CoachMarkPlacement.above,
          stepLabel: '2 / 3',
          onSkip: controller.complete,
          revealTarget: true,
        ),
      ],
      TutorialReviewResult(:final requestId) when requestId == currentEntryId =>
        [
          CoachMarkHint(
            key: const ValueKey(CoachMarkTarget.tryonRating),
            target: CoachMarkTarget.tryonRating,
            message: reviewMessage,
            action: (
              label: CoachMarkHint.doneLabel,
              onPressed: controller.complete,
            ),
            placement: CoachMarkPlacement.left,
            stepLabel: '3 / 3',
          ),
        ],
      _ => const [],
    };

    return OverlayPortal(
      controller: portal,
      overlayChildBuilder: (final _) => Stack(children: hints),
      child: child,
    );
  }
}
