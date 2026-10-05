import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/page_linked_reveal.dart';

void main() {
  late PageController controller;

  setUp(() => controller = PageController());
  tearDown(() => controller.dispose());

  Future<void> pumpHost(final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            PageView(
              controller: controller,
              children: const [
                SizedBox.expand(),
                SizedBox.expand(),
                SizedBox.expand(),
              ],
            ),
            PageLinkedReveal(
              controller: controller,
              interval: const Interval(0, 0.5),
              showOnAvatarPage: true,
              child: const Text('avatar'),
            ),
            PageLinkedReveal(
              controller: controller,
              interval: const Interval(0.5, 1),
              child: const Text('result'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double opacityOf(final WidgetTester tester, final String label) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      )
      .opacity;

  bool ignoresTaps(final WidgetTester tester, final String label) => tester
      .widget<IgnorePointer>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(IgnorePointer),
            )
            .first,
      )
      .ignoring;

  testWidgets('the avatar page shows only its own chrome', (
    final tester,
  ) async {
    await pumpHost(tester);

    expect(opacityOf(tester, 'avatar'), 1);
    expect(ignoresTaps(tester, 'avatar'), isFalse);
    expect(opacityOf(tester, 'result'), 0);
    expect(ignoresTaps(tester, 'result'), isTrue);
  });

  testWidgets('result pages swap the chrome over', (final tester) async {
    await pumpHost(tester);

    controller.jumpToPage(2);
    await tester.pump();

    expect(opacityOf(tester, 'avatar'), 0);
    expect(opacityOf(tester, 'result'), 1);
    expect(ignoresTaps(tester, 'result'), isFalse);
  });

  testWidgets('midway through the swipe neither side is shown', (
    final tester,
  ) async {
    await pumpHost(tester);

    controller.jumpTo(controller.position.viewportDimension * 0.5);
    await tester.pump();

    expect(opacityOf(tester, 'avatar'), 0);
    expect(opacityOf(tester, 'result'), 0);
  });
}
