import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_registry.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/bottom_nav_bar_inset.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:visibility_detector/visibility_detector.dart';

const _target = CoachMarkTarget.firstProductTryon;
const _longMessage = '完成第一次試穿！左右滑動切換結果，喜歡就按讚，再多寫一些字讓泡泡撐到最寬';

void main() {
  Finder bubble() => find.byKey(CoachMarkHint.bubbleKey);
  Finder beacon() => find.byKey(CoachMarkHint.beaconKey);
  Finder caret() => find.byKey(CoachMarkHint.caretKey);

  Future<void> settle(final WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
  }

  Future<void> pumpScene(
    final WidgetTester tester, {
    required final Widget page,
    final String message = 'hint',
    final CoachMarkPlacement placement = CoachMarkPlacement.below,
    final VoidCallback? onSkip,
    final CoachMarkAction? action,
    final bool disableAnimations = true,
    final EdgeInsets padding = EdgeInsets.zero,
    final double navBarInset = 0,
    final bool revealTarget = false,
    final String? stepLabel,
    final Radius? targetRadius,
    final double targetGap = 0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (final context, final child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations, padding: padding),
            child: BottomNavBarInset(overlap: navBarInset, child: child!),
          ),
          home: Scaffold(
            body: Stack(
              children: [
                page,
                CoachMarkHint(
                  target: _target,
                  message: message,
                  placement: placement,
                  onSkip: onSkip,
                  action: action,
                  revealTarget: revealTarget,
                  stepLabel: stepLabel,
                  targetRadius: targetRadius,
                  targetGap: targetGap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Widget anchor({
    final VoidCallback? onTap,
    final Size size = const Size(80, 40),
  }) => CoachMarkAnchor(
    target: _target,
    child: SizedBox.fromSize(
      size: size,
      child: ElevatedButton(onPressed: onTap ?? () {}, child: const Text('t')),
    ),
  );

  Widget centered({
    final VoidCallback? onTarget,
    final VoidCallback? onBehind,
  }) => Stack(
    children: [
      Align(
        alignment: Alignment.topLeft,
        child: TextButton(
          onPressed: onBehind ?? () {},
          child: const Text('behind'),
        ),
      ),
      Center(child: anchor(onTap: onTarget)),
    ],
  );

  testWidgets('shows the bubble while its target is fully visible', (
    final tester,
  ) async {
    await pumpScene(tester, page: centered());

    expect(find.text('hint').hitTestable(), findsOneWidget);
    expect(beacon(), findsOneWidget);
  });

  testWidgets('the beacon sits on the centre of its target', (
    final tester,
  ) async {
    await pumpScene(tester, page: centered());

    expect(
      tester.getCenter(beacon()),
      offsetMoreOrLessEquals(tester.getCenter(find.byType(CoachMarkAnchor))),
    );
  });

  testWidgets('a short message hugs its content', (final tester) async {
    await pumpScene(tester, page: centered());

    expect(tester.getSize(bubble()).width, lessThan(CoachMarkHint.maxWidth));
  });

  testWidgets('a below bubble points up at its target even when pushed '
      'aside by the screen edge', (final tester) async {
    await pumpScene(
      tester,
      message: _longMessage,
      page: Align(alignment: const Alignment(-0.9, 0), child: anchor()),
    );

    final rect = tester.getRect(bubble());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    expect(rect.top, greaterThan(target.bottom));
    expect(rect.center.dx, greaterThan(target.center.dx));
    expect(tester.getRect(caret()).top, moreOrLessEquals(rect.top));
    expect(tester.getCenter(caret()).dx, moreOrLessEquals(target.center.dx));
  });

  testWidgets('an above bubble points down at its target', (
    final tester,
  ) async {
    await pumpScene(
      tester,
      placement: CoachMarkPlacement.above,
      page: centered(),
    );

    final rect = tester.getRect(bubble());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    expect(rect.bottom, lessThan(target.top));
    expect(tester.getRect(caret()).bottom, moreOrLessEquals(rect.bottom));
    expect(tester.getCenter(caret()).dx, moreOrLessEquals(target.center.dx));
  });

  testWidgets('mounts nothing when its target is absent', (final tester) async {
    await pumpScene(tester, page: const SizedBox.expand());

    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);
  });

  testWidgets('mounts nothing while its target sits on a paused page', (
    final tester,
  ) async {
    await pumpScene(
      tester,
      page: TickerMode(enabled: false, child: centered()),
    );

    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);
  });

  testWidgets('taps outside the bubble reach the widgets underneath', (
    final tester,
  ) async {
    var targetTaps = 0;
    var behindTaps = 0;
    await pumpScene(
      tester,
      page: centered(
        onTarget: () => targetTaps++,
        onBehind: () => behindTaps++,
      ),
    );

    await tester.tap(find.text('t'));
    await tester.tap(find.text('behind'));

    expect(targetTaps, 1);
    expect(behindTaps, 1);
  });

  testWidgets('skip and action call back', (final tester) async {
    var skips = 0;
    var actions = 0;
    await pumpScene(
      tester,
      page: centered(),
      onSkip: () => skips++,
      action: (label: 'go', onPressed: () => actions++),
    );

    await tester.tap(find.text(CoachMarkHint.skipLabel));
    await tester.tap(find.text('go'));

    expect(skips, 1);
    expect(actions, 1);
  });

  testWidgets('no skip button without onSkip', (final tester) async {
    await pumpScene(tester, page: centered());

    expect(find.text(CoachMarkHint.skipLabel), findsNothing);
  });

  testWidgets('the beacon rings the target rather than covering its label', (
    final tester,
  ) async {
    await pumpScene(tester, page: centered());

    final ring = tester.getRect(beacon());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    expect(ring.center, target.center);
    expect(ring.width, greaterThan(target.width));
    expect(ring.height, greaterThan(target.height));
  });

  testWidgets('a rectangular target gets a beacon hugging its corners', (
    final tester,
  ) async {
    const radius = Radius.circular(AppRadius.button);
    await pumpScene(tester, page: centered(), targetRadius: radius);

    final ring = tester.getRect(beacon());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    const edge = AppStroke.medium / 2;
    final hug = target.shift(-ring.topLeft).inflate(edge);
    expect(
      find.descendant(of: beacon(), matching: find.byType(CustomPaint)),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          hug,
          radius + const Radius.circular(edge),
        ),
      ),
    );
  });

  testWidgets('a target gap leaves room between the target and the beacon', (
    final tester,
  ) async {
    const radius = Radius.circular(AppRadius.button);
    const gap = AppSpacing.sm;
    await pumpScene(
      tester,
      page: centered(),
      targetRadius: radius,
      targetGap: gap,
    );

    final ring = tester.getRect(beacon());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    const outset = gap + AppStroke.medium / 2;
    expect(
      find.descendant(of: beacon(), matching: find.byType(CustomPaint)),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          target.shift(-ring.topLeft).inflate(outset),
          radius + const Radius.circular(outset),
        ),
      ),
    );
  });

  testWidgets('the bubble shows its step and skip in a header', (
    final tester,
  ) async {
    await pumpScene(
      tester,
      page: centered(),
      stepLabel: '2 / 3',
      onSkip: () {},
    );

    final step = tester.getRect(find.text('2 / 3'));
    final skip = tester.getRect(find.text(CoachMarkHint.skipLabel));
    final message = tester.getRect(find.text('hint'));
    expect(step.bottom, lessThanOrEqualTo(message.top));
    expect(skip.bottom, lessThanOrEqualTo(message.top));
    expect(skip.left, greaterThan(step.right));
  });

  testWidgets('the beacon only pulses when motion is allowed', (
    final tester,
  ) async {
    double pulse() {
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(of: beacon(), matching: find.byType(CustomPaint)),
          )
          .painter!;
      // ignore: avoid_dynamic_calls
      return ((painter as dynamic).pulse as Animation<double>).value;
    }

    await pumpScene(tester, page: centered());
    await tester.pump(const Duration(milliseconds: 750));
    expect(pulse(), 0);

    await pumpScene(tester, page: centered(), disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 750));
    expect(pulse(), greaterThan(0));
  });

  testWidgets('the beacon paints without opacity or transform layers, which '
      'would stop the iOS 26 native tab bar taking touches', (
    final tester,
  ) async {
    await pumpScene(tester, page: centered(), disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.descendant(
        of: beacon(),
        matching: find.byWidgetPredicate(
          (final w) =>
              w is FadeTransition ||
              w is ScaleTransition ||
              w is Opacity ||
              w is Transform,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('hides, beacon included, while the target is scrolled partly '
      'out, and returns once it is fully back', (final tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      page: ListView(
        controller: controller,
        children: [
          const SizedBox(height: 300),
          Align(alignment: Alignment.centerLeft, child: anchor()),
          const SizedBox(height: 1000),
        ],
      ),
    );
    expect(bubble(), findsOneWidget);

    controller.jumpTo(320);
    await settle(tester);
    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);

    controller.jumpTo(100);
    await settle(tester);
    expect(bubble(), findsOneWidget);
    expect(beacon(), findsOneWidget);
  });

  testWidgets('places the bubble on screen outside a scroll view that '
      'shrink-wraps its target', (final tester) async {
    await pumpScene(
      tester,
      page: Center(
        child: SingleChildScrollView(child: anchor(size: const Size(300, 200))),
      ),
    );

    expect(bubble().hitTestable(), findsOneWidget);
  });

  testWidgets('hides while the target is under the bottom chrome', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      padding: const EdgeInsets.only(bottom: 34),
      navBarInset: 60,
      page: ListView(
        controller: controller,
        children: [
          const SizedBox(height: 480),
          Align(alignment: Alignment.centerLeft, child: anchor()),
          const SizedBox(height: 1000),
        ],
      ),
    );
    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);
    expect(controller.offset, 0);

    controller.jumpTo(100);
    await settle(tester);
    expect(bubble(), findsOneWidget);
  });

  Widget listWithTargetAt(
    final double top,
    final ScrollController controller,
  ) => ListView(
    controller: controller,
    children: [
      SizedBox(height: top),
      Align(alignment: Alignment.centerLeft, child: anchor()),
      const SizedBox(height: 1000),
    ],
  );

  testWidgets('reveals a target under the bottom chrome once, then leaves '
      'scrolling to the user', (final tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      padding: const EdgeInsets.only(bottom: 34),
      navBarInset: 60,
      page: listWithTargetAt(480, controller),
    );
    await settle(tester);

    expect(controller.offset, greaterThan(0));
    expect(bubble(), findsOneWidget);

    controller.jumpTo(0);
    await settle(tester);
    await settle(tester);

    expect(controller.offset, 0);
    expect(bubble(), findsNothing);
  });

  testWidgets('reveals a target cut off by the screen edge', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      page: listWithTargetAt(580, controller),
    );
    await settle(tester);

    expect(controller.offset, greaterThan(0));
    expect(bubble(), findsOneWidget);
  });

  testWidgets('leaves an already presentable target where it is', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      page: listWithTargetAt(100, controller),
    );
    await settle(tester);

    expect(controller.offset, 0);
    expect(bubble(), findsOneWidget);
  });

  testWidgets('never reveals a target whose tickers are paused', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      padding: const EdgeInsets.only(bottom: 34),
      navBarInset: 60,
      page: TickerMode(
        enabled: false,
        child: listWithTargetAt(480, controller),
      ),
    );
    await settle(tester);

    expect(controller.offset, 0);
  });

  testWidgets('reveals a lazily built target still entirely below the fold', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      page: listWithTargetAt(700, controller),
    );
    await settle(tester);

    expect(controller.offset, greaterThan(0));
    expect(bubble(), findsOneWidget);
  });

  testWidgets('reveals a target once its paused page comes on screen', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final onScreen = ValueNotifier(false);
    addTearDown(onScreen.dispose);
    await pumpScene(
      tester,
      revealTarget: true,
      padding: const EdgeInsets.only(bottom: 34),
      navBarInset: 60,
      page: ValueListenableBuilder(
        valueListenable: onScreen,
        builder: (final _, final enabled, final child) =>
            TickerMode(enabled: enabled, child: child!),
        child: listWithTargetAt(480, controller),
      ),
    );
    await settle(tester);
    expect(controller.offset, 0);

    onScreen.value = true;
    await settle(tester);
    await settle(tester);

    expect(controller.offset, greaterThan(0));
    expect(bubble(), findsOneWidget);
  });

  Widget pinnedHeaderList(final ScrollController controller) =>
      CustomScrollView(
        controller: controller,
        slivers: [
          PinnedHeaderSliver(
            child: Container(
              height: 60,
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () {}, child: const Text('sort')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 300)),
          SliverToBoxAdapter(
            child: Align(alignment: Alignment.centerLeft, child: anchor()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 1000)),
        ],
      );

  testWidgets('hides while the target slides under a pinned header', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(tester, page: pinnedHeaderList(controller));
    expect(bubble(), findsOneWidget);

    controller.jumpTo(310);
    await settle(tester);

    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);
    expect(find.text('sort').hitTestable(), findsOneWidget);
  });

  testWidgets('flips below rather than cover a pinned header', (
    final tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpScene(
      tester,
      placement: CoachMarkPlacement.above,
      page: pinnedHeaderList(controller),
    );

    controller.jumpTo(280);
    await settle(tester);

    final target = tester.getRect(find.byType(CoachMarkAnchor));
    expect(tester.getRect(bubble()).top, greaterThan(target.bottom));
    expect(find.text('sort').hitTestable(), findsOneWidget);
  });

  testWidgets('keeps a centred bubble on screen near the edge', (
    final tester,
  ) async {
    await pumpScene(
      tester,
      message: _longMessage,
      page: Align(alignment: Alignment.centerLeft, child: anchor()),
    );

    final rect = tester.getRect(bubble());
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(800));
  });

  testWidgets('a left bubble fits the room beside a target on a narrow '
      'screen', (final tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScene(
      tester,
      message: _longMessage,
      placement: CoachMarkPlacement.left,
      page: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: anchor(size: const Size(40, 80)),
        ),
      ),
    );

    final rect = tester.getRect(bubble());
    final target = tester.getRect(find.byType(CoachMarkAnchor));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(target.left));
    expect(tester.getRect(caret()).right, moreOrLessEquals(rect.right));
    expect(tester.getCenter(caret()).dy, moreOrLessEquals(target.center.dy));
  });

  testWidgets('never puts a follower layer in the scene, which would stop '
      'the iOS 26 native tab bar taking touches', (final tester) async {
    await pumpScene(tester, page: Center(child: anchor()));

    expect(bubble(), findsOneWidget);
    expect(beacon(), findsOneWidget);
    expect(find.byType(CompositedTransformFollower), findsNothing);
  });

  testWidgets('an anchor alone builds no tracking widgets and registers its '
      'context only while mounted', (final tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final anchors = ValueNotifier(1);
    addTearDown(anchors.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ValueListenableBuilder(
            valueListenable: anchors,
            builder: (final _, final count, final _) =>
                Column(children: [for (var i = 0; i < count; i++) anchor()]),
          ),
        ),
      ),
    );
    await settle(tester);
    final registry = container.read(coachMarkRegistryProvider);

    expect(find.byType(VisibilityDetector), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(
      registry.anchorOf(_target),
      tester.element(find.byType(CoachMarkAnchor)),
    );

    anchors.value = 2;
    await settle(tester);
    final second = tester.element(find.byType(CoachMarkAnchor).last);
    expect(registry.anchorOf(_target), second);

    anchors.value = 0;
    await settle(tester);
    expect(registry.anchorOf(_target), isNull);
  });

  testWidgets('shows nothing when the bubble fits on neither side', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScene(
      tester,
      message: _longMessage,
      onSkip: () {},
      action: (label: 'go', onPressed: () {}),
      page: centered(),
    );

    expect(bubble(), findsNothing);
    expect(beacon(), findsNothing);
  });

  testWidgets('never covers a pinned header while measuring its bubble', (
    final tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 280);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                pinnedHeaderList(controller),
                const CoachMarkHint(
                  target: _target,
                  message: _longMessage,
                  placement: CoachMarkPlacement.above,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (var frame = 0; frame < 8; frame++) {
      await tester.pump();
      expect(find.text('sort').hitTestable(), findsOneWidget);
    }
    expect(find.text(_longMessage).hitTestable(), findsOneWidget);
  });

  group('CoachMarkChromeHint', () {
    Future<void> pumpChromeHint(
      final WidgetTester tester, {
      final VoidCallback? onSkip,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (final context, final child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: BottomNavBarInset(overlap: 50, child: child!),
          ),
          home: Stack(
            children: [
              CoachMarkChromeHint(
                message: 'hint',
                stepLabel: '1 / 2',
                onSkip: onSkip,
              ),
            ],
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('sits centred above the bottom chrome, clear of a FAB', (
      final tester,
    ) async {
      await pumpChromeHint(tester);

      final rect = tester.getRect(bubble());
      expect(rect.center.dx, moreOrLessEquals(200));
      expect(
        rect.bottom,
        moreOrLessEquals(800 - 34 - 50 - AppSpacing.fabClearance),
      );
    });

    testWidgets('points down from its centre and rings nothing', (
      final tester,
    ) async {
      await pumpChromeHint(tester);

      expect(find.text('hint').hitTestable(), findsOneWidget);
      final caretRect = tester.getRect(caret());
      final bubbleRect = tester.getRect(bubble());
      expect(caretRect.center.dx, moreOrLessEquals(bubbleRect.center.dx));
      expect(caretRect.bottom, moreOrLessEquals(bubbleRect.bottom));
      expect(beacon(), findsNothing);
    });

    testWidgets('skip calls back', (final tester) async {
      var skips = 0;
      await pumpChromeHint(tester, onSkip: () => skips++);

      await tester.tap(find.text(CoachMarkHint.skipLabel));

      expect(skips, 1);
    });
  });
}
