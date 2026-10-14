import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/widgets/tutorial_overlay.dart';

class _FakeTutorial extends TutorialController {
  _FakeTutorial(this._initial);

  final TutorialState _initial;
  var completions = 0;

  @override
  TutorialState build() => _initial;

  @override
  Future<void> complete() async => completions++;
}

class _FakeGallery extends TryonGalleryNotifier {
  _FakeGallery(this._currentId);

  final String? _currentId;

  @override
  TryonGalleryState build() => TryonGalleryState(currentId: _currentId);
}

void main() {
  late _FakeTutorial tutorial;

  Future<void> pumpOverlay(
    final WidgetTester tester,
    final TutorialState state, {
    final String? currentEntryId,
    final PersonalTab currentTab = PersonalTab.home,
  }) async {
    tutorial = _FakeTutorial(state);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorialControllerProvider.overrideWith(() => tutorial),
          tryonGalleryProvider.overrideWith(() => _FakeGallery(currentEntryId)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (final context, final child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: TutorialOverlay(
            currentTab: currentTab,
            child: const Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    bottom: 0,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.shopTab,
                      child: SizedBox(width: 68, height: 56),
                    ),
                  ),
                  Align(
                    alignment: Alignment(-0.3, 0.2),
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.firstProductTryon,
                      child: SizedBox(width: 80, height: 32),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: 120,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.tryonRating,
                      child: SizedBox(width: 40, height: 80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
  }

  Finder visible(final String text) => find.text(text).hitTestable();

  testWidgets('inactive shows nothing', (final tester) async {
    await pumpOverlay(tester, const TutorialState.inactive());
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('pick model shows nothing', (final tester) async {
    await pumpOverlay(tester, const TutorialState.pickModel());
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('start try-on points at the shop tab and the product button', (
    final tester,
  ) async {
    await pumpOverlay(tester, const TutorialState.startTryon());

    expect(visible(TutorialOverlay.shopTabMessage), findsOneWidget);
    expect(visible(TutorialOverlay.tapTryonMessage), findsOneWidget);
    expect(
      tester.getRect(find.byKey(CoachMarkHint.bubbleKey).first).bottom,
      lessThan(
        tester
            .getRect(
              find.byWidgetPredicate(
                (final w) =>
                    w is CoachMarkAnchor && w.target == CoachMarkTarget.shopTab,
              ),
            )
            .top,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(TutorialOverlay.shopTabMessage),
          matching: find.byKey(CoachMarkHint.bubbleKey),
        ),
        matching: find.text(CoachMarkHint.skipLabel),
      ),
    );
    expect(tutorial.completions, 1);
  });

  testWidgets('the shop tab hint hides once the shop tab is open', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const TutorialState.startTryon(),
      currentTab: PersonalTab.shop,
    );

    expect(find.text(TutorialOverlay.shopTabMessage), findsNothing);
    expect(visible(TutorialOverlay.tapTryonMessage), findsOneWidget);
  });

  testWidgets('the product hint scrolls its button into view', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const TutorialState.startTryon(),
      currentTab: PersonalTab.shop,
    );

    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.firstProductTryon)),
          )
          .revealTarget,
      isTrue,
    );
  });

  testWidgets('generating shows nothing', (final tester) async {
    await pumpOverlay(tester, const TutorialState.generating({'r1'}));
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('review hides while another result is current', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const TutorialState.reviewResult('r1'),
      currentEntryId: 'other',
    );
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('review shows on its own result and done completes', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const TutorialState.reviewResult('r1'),
      currentEntryId: 'r1',
    );
    expect(visible(TutorialOverlay.reviewMessage), findsOneWidget);
    expect(find.text(CoachMarkHint.skipLabel), findsNothing);

    await tester.tap(visible(TutorialOverlay.doneLabel));
    expect(tutorial.completions, 1);
  });

  testWidgets('skip completes the tutorial', (final tester) async {
    await pumpOverlay(
      tester,
      const TutorialState.startTryon(),
      currentTab: PersonalTab.shop,
    );

    await tester.tap(visible(CoachMarkHint.skipLabel));

    expect(tutorial.completions, 1);
  });

  testWidgets('the review bubble stays on a 360dp screen', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpOverlay(
      tester,
      const TutorialState.reviewResult('r1'),
      currentEntryId: 'r1',
    );

    final bubble = tester.getRect(find.byKey(CoachMarkHint.bubbleKey));
    expect(bubble.left, greaterThanOrEqualTo(0));
    expect(
      bubble.right,
      lessThanOrEqualTo(tester.getRect(find.byType(CoachMarkAnchor).last).left),
    );
  });
}
