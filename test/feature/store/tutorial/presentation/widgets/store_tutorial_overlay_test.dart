import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/shells/store_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/widgets/store_tutorial_overlay.dart';

class _FakeTutorial extends StoreTutorialController {
  _FakeTutorial(this._initial);

  final StoreTutorialState _initial;
  var nexts = 0;
  var finishes = 0;
  var accountTabOpens = 0;

  @override
  StoreTutorialState build() => _initial;

  @override
  void next() => nexts++;

  @override
  Future<void> finish() async => finishes++;

  @override
  void accountTabOpened() => accountTabOpens++;
}

void main() {
  late _FakeTutorial tutorial;

  Future<void> pumpOverlay(
    final WidgetTester tester,
    final StoreTutorialState state, {
    final StoreTab currentTab = StoreTab.products,
  }) async {
    tutorial = _FakeTutorial(state);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeTutorialControllerProvider.overrideWith(() => tutorial),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (final context, final child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: StoreTutorialOverlay(
            currentTab: currentTab,
            child: const Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: 120,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.storeProductsAddFab,
                      child: SizedBox(width: 56, height: 56),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    bottom: 120,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.storeAccountAddFab,
                      child: SizedBox(width: 56, height: 56),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    top: 360,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.storeFirstProductStats,
                      child: SizedBox(width: 120, height: 16),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    top: 80,
                    child: CoachMarkAnchor(
                      target: CoachMarkTarget.storePerformance,
                      child: SizedBox(width: 160, height: 80),
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

  Finder hintFor(final CoachMarkTarget target) => find.byKey(ValueKey(target));

  testWidgets('inactive shows nothing', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.inactive());
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('step 1 points at the FAB of the current tab', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.addProduct(),
      currentTab: StoreTab.account,
    );

    expect(hintFor(CoachMarkTarget.storeAccountAddFab), findsOneWidget);
    expect(hintFor(CoachMarkTarget.storeProductsAddFab), findsNothing);
    expect(visible(StoreTutorialOverlay.addProductMessage), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);

    await tester.tap(visible(CoachMarkHint.skipLabel));
    expect(tutorial.finishes, 1);
  });

  testWidgets('step 9 advances with next', (final tester) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );

    expect(
      visible(StoreTutorialOverlay.reviewActiveProductMessage),
      findsOneWidget,
    );
    expect(find.text('10 / 12'), findsOneWidget);

    await tester.tap(visible(CoachMarkHint.nextLabel));
    expect(tutorial.nexts, 1);
  });

  testWidgets('reviewing an unlisted product explains how to publish it', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.reviewProduct(status: ProductStatus.archived),
    );

    expect(
      visible(StoreTutorialOverlay.reviewArchivedProductMessage),
      findsOneWidget,
    );
    expect(find.text('10 / 12'), findsOneWidget);
  });

  // The card menu sits in the card's bottom row beside the stats this hint
  // rings, so the copy must send the brand there and not to the image corner.
  test('the archived copy points at the bottom corner that holds the menu', () {
    expect(
      StoreTutorialOverlay.reviewArchivedProductMessage,
      allOf(contains('右下角'), isNot(contains('右上角'))),
    );
  });

  testWidgets('skipping step 9 finishes the tour', (final tester) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );

    await tester.tap(visible(CoachMarkHint.skipLabel));

    expect(tutorial.finishes, 1);
  });

  testWidgets('step 10 asks for the account tab and has no done button', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.openAccount());

    expect(find.byType(CoachMarkChromeHint), findsOneWidget);
    expect(visible(StoreTutorialOverlay.accountTabMessage), findsOneWidget);
    expect(find.text('11 / 12'), findsOneWidget);
    expect(find.text(CoachMarkHint.doneLabel), findsNothing);

    await tester.tap(visible(CoachMarkHint.skipLabel));
    expect(tutorial.finishes, 1);
  });

  testWidgets('being on the account tab at step 10 moves on to step 11', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.openAccount(),
      currentTab: StoreTab.account,
    );

    expect(tutorial.accountTabOpens, 1);
  });

  testWidgets('step 11 points at the performance card on the account tab', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.viewPerformance(),
      currentTab: StoreTab.account,
    );

    expect(hintFor(CoachMarkTarget.storePerformance), findsOneWidget);
    expect(visible(StoreTutorialOverlay.performanceMessage), findsOneWidget);
    expect(find.text('12 / 12'), findsOneWidget);
    expect(
      tester
          .widget<CoachMarkHint>(hintFor(CoachMarkTarget.storePerformance))
          .revealTarget,
      isTrue,
    );

    await tester.tap(visible(CoachMarkHint.doneLabel));
    expect(tutorial.finishes, 1);
  });

  testWidgets('form steps show nothing in the shell', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.pickImage());
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  testWidgets('step 9 sits above the product stats it describes', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );

    final hint = tester.widget<CoachMarkHint>(
      hintFor(CoachMarkTarget.storeFirstProductStats),
    );
    expect(hint.placement, CoachMarkPlacement.above);
    expect(
      tester.getRect(find.byKey(CoachMarkHint.bubbleKey)).bottom,
      lessThan(
        tester
            .getRect(
              find.byWidgetPredicate(
                (final w) =>
                    w is CoachMarkAnchor &&
                    w.target == CoachMarkTarget.storeFirstProductStats,
              ),
            )
            .top,
      ),
    );
  });

  testWidgets('the performance step hugs the card corners', (
    final tester,
  ) async {
    await pumpOverlay(
      tester,
      const StoreTutorialState.viewPerformance(),
      currentTab: StoreTab.account,
    );

    expect(
      tester
          .widget<CoachMarkHint>(hintFor(CoachMarkTarget.storePerformance))
          .targetRadius,
      const Radius.circular(AppRadius.card),
    );
  });
}
