import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/pinch_to_zoom.dart';

void main() {
  const photo = Key('photo');
  final pageController = PageController();
  var taps = 0;

  // Mirrors the home page: pull-to-refresh scroll view around a paging gallery.
  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 600,
            child: PageView(
              controller: pageController,
              children: [
                GestureDetector(
                  onTap: () => taps++,
                  child: const PinchToZoom(
                    child: ColoredBox(key: photo, color: Colors.red),
                  ),
                ),
                const SizedBox.expand(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  setUp(() => taps = 0);
  tearDownAll(pageController.dispose);

  Future<(TestGesture, TestGesture)> pinchOpen(final WidgetTester tester) async {
    final center = tester.getCenter(find.byKey(photo));
    final first = await tester.startGesture(center - const Offset(20, 0), pointer: 1);
    final second = await tester.startGesture(center + const Offset(20, 0), pointer: 2);
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(-10, 0));
      await second.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    return (first, second);
  }

  testWidgets('a pinch zooms a copy above the page without paging', (final tester) async {
    await tester.pumpWidget(buildSubject());
    final original = tester.getRect(find.byKey(photo));

    final (first, second) = await pinchOpen(tester);

    expect(find.byKey(photo), findsNWidgets(2));
    expect(tester.getRect(find.byKey(photo).last).width, greaterThan(original.width));
    expect(pageController.page, 0);

    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(find.byKey(photo), findsOneWidget);
    expect(tester.getRect(find.byKey(photo)), original);
    expect(pageController.page, 0);
    expect(taps, 0);
  });

  testWidgets('keeps zooming when one of three fingers lifts', (final tester) async {
    await tester.pumpWidget(buildSubject());
    final (first, second) = await pinchOpen(tester);
    final third = await tester.startGesture(
      tester.getCenter(find.byKey(photo).first) + const Offset(0, 40),
      pointer: 3,
    );
    await tester.pump();

    await third.up();
    await tester.pumpAndSettle();
    expect(find.byKey(photo), findsNWidgets(2));

    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(find.byKey(photo), findsOneWidget);
  });

  testWidgets('an iOS pinch that drifts while spreading still zooms', (
    final tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    final center = tester.getCenter(find.byKey(photo));
    final first = await tester.startGesture(center - const Offset(20, 0), pointer: 1);
    final second = await tester.startGesture(center + const Offset(20, 0), pointer: 2);
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(-1, -6));
      await second.moveBy(const Offset(1, -6));
      await tester.pump();
    }

    expect(find.byKey(photo), findsNWidgets(2));
    expect(pageController.page, 0);

    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a one-finger swipe still pages', (final tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.fling(find.byKey(photo), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(pageController.page, 1);
  });

  testWidgets('a tap still reaches the enclosing detector', (final tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byKey(photo));
    await tester.pump();

    expect(taps, 1);
    expect(find.byKey(photo), findsOneWidget);
  });
}
