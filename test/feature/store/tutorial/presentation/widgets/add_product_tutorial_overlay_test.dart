import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/widgets/add_product_tutorial_overlay.dart';

class _FakeTutorial extends StoreTutorialController {
  _FakeTutorial(this._initial);

  final StoreTutorialState _initial;
  var enters = 0;
  var leaves = 0;
  var nexts = 0;
  var finishes = 0;

  @override
  StoreTutorialState build() => _initial;

  @override
  void enterAddProduct() => enters++;

  @override
  void leaveAddProduct() => leaves++;

  @override
  void next() => nexts++;

  @override
  Future<void> finish() async => finishes++;
}

const _anchors = [
  (CoachMarkTarget.productImages, Alignment(0, -0.8)),
  (CoachMarkTarget.productImageAnalyzing, Alignment(0, -0.5)),
  (CoachMarkTarget.productName, Alignment(0, -0.2)),
  (CoachMarkTarget.productPrice, Alignment(0, 0.05)),
  (CoachMarkTarget.productPurchaseLink, Alignment(0, 0.3)),
  (CoachMarkTarget.productSizeVoice, Alignment(0.8, 0.5)),
  (CoachMarkTarget.productSave, Alignment(0.9, -0.95)),
];

void main() {
  late _FakeTutorial tutorial;
  late ProviderContainer container;

  Future<void> pumpOverlay(
    final WidgetTester tester,
    final StoreTutorialState state,
  ) async {
    tutorial = _FakeTutorial(state);
    container = ProviderContainer(
      overrides: [storeTutorialControllerProvider.overrideWith(() => tutorial)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (final context, final child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: AddProductTutorialOverlay(
            child: Scaffold(
              body: Stack(
                children: [
                  for (final (target, alignment) in _anchors)
                    Align(
                      alignment: alignment,
                      child: CoachMarkAnchor(
                        target: target,
                        child: const SizedBox(width: 48, height: 40),
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

  testWidgets('mounting enters and unmounting leaves the add page', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.pickImage());
    expect(tutorial.enters, 1);
    expect(tutorial.leaves, 0);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SizedBox()),
    );
    await tester.pump();

    expect(tutorial.leaves, 1);
  });

  testWidgets('pick image shows step 2', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.pickImage());

    expect(visible(AddProductTutorialOverlay.pickImageMessage), findsOneWidget);
    expect(find.text('2 / 11'), findsOneWidget);
    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productImages)),
          )
          .targetRadius,
      const Radius.circular(AppRadius.button),
    );
    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productImages)),
          )
          .targetGap,
      0,
    );

    await tester.tap(visible(CoachMarkHint.skipLabel));
    expect(tutorial.finishes, 1);
  });

  testWidgets('analyzing points at the analysis indicator', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.analyzing());

    expect(
      find.byKey(const ValueKey(CoachMarkTarget.productImageAnalyzing)),
      findsOneWidget,
    );
    expect(visible(AddProductTutorialOverlay.analyzingMessage), findsOneWidget);
    expect(find.text('3 / 11'), findsOneWidget);
    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productImageAnalyzing)),
          )
          .targetGap,
      AppSpacing.sm,
    );
  });

  testWidgets('review info asks to check what AI filled', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.reviewInfo());

    expect(visible(AddProductTutorialOverlay.reviewMessage), findsOneWidget);
    expect(find.text('4 / 11'), findsOneWidget);

    await tester.tap(visible(CoachMarkHint.nextLabel));
    expect(tutorial.nexts, 1);
  });

  testWidgets('form hints below the fold scroll into view', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.sizes());

    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productSizeVoice)),
          )
          .revealTarget,
      isTrue,
    );
  });

  testWidgets('save shows step 6 without a next button', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.save());

    expect(visible(AddProductTutorialOverlay.saveMessage), findsOneWidget);
    expect(find.text('8 / 11'), findsOneWidget);
    expect(find.text(CoachMarkHint.nextLabel), findsNothing);
  });

  testWidgets('shell steps show nothing here', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.addProduct());
    expect(find.byType(CoachMarkHint), findsNothing);
  });

  CoachMarkPlacement placementOf(
    final WidgetTester tester,
    final CoachMarkTarget target,
  ) => tester.widget<CoachMarkHint>(find.byKey(ValueKey(target))).placement;

  testWidgets('step 3 sits above the name so it never covers the price', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.reviewInfo());

    expect(
      placementOf(tester, CoachMarkTarget.productName),
      CoachMarkPlacement.above,
    );
  });

  testWidgets('step 5 sits above the voice button so it never covers sizes', (
    final tester,
  ) async {
    await pumpOverlay(tester, const StoreTutorialState.sizes());

    expect(
      placementOf(tester, CoachMarkTarget.productSizeVoice),
      CoachMarkPlacement.above,
    );
  });

  testWidgets('input steps hug the input box corners', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.purchaseLink());

    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productPurchaseLink)),
          )
          .targetRadius,
      const Radius.circular(AppRadius.input),
    );
  });

  testWidgets('the name step hugs the input box corners', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.reviewInfo());

    expect(
      tester
          .widget<CoachMarkHint>(
            find.byKey(const ValueKey(CoachMarkTarget.productName)),
          )
          .targetRadius,
      const Radius.circular(AppRadius.input),
    );
  });

  testWidgets('the price step points at the price box', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.price());

    final hint = tester.widget<CoachMarkHint>(
      find.byKey(const ValueKey(CoachMarkTarget.productPrice)),
    );
    expect(visible(AddProductTutorialOverlay.priceMessage), findsOneWidget);
    expect(find.text('5 / 11'), findsOneWidget);
    expect(hint.targetRadius, const Radius.circular(AppRadius.input));
    expect(hint.revealTarget, isTrue);

    await tester.tap(visible(CoachMarkHint.nextLabel));
    expect(tutorial.nexts, 1);
  });

  testWidgets('the purchase-link step is step 5', (final tester) async {
    await pumpOverlay(tester, const StoreTutorialState.purchaseLink());

    expect(find.text('6 / 11'), findsOneWidget);
  });
}
