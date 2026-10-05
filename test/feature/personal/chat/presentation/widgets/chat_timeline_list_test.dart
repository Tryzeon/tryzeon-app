import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_timeline_list.dart';

void main() {
  final controller = ScrollController();

  Future<void> pumpTimeline(
    final WidgetTester tester,
    final List<String> messages,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatTimelineList(
          entries: [for (final text in messages) ChatUserEntry(text)],
          controller: controller,
          onStarterTap: (final _) {},
          onRetry: () {},
          onUpgrade: () {},
        ),
      ),
    ),
  );

  double opacityOf(final WidgetTester tester, final String text) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
      )
      .opacity;

  testWidgets('entries present on first build render without an entrance', (
    final tester,
  ) async {
    await pumpTimeline(tester, ['a', 'b']);

    expect(opacityOf(tester, 'a'), 1);
    expect(opacityOf(tester, 'b'), 1);
  });

  testWidgets('an appended entry fades in once and existing ones stay put', (
    final tester,
  ) async {
    await pumpTimeline(tester, ['a', 'b']);
    await pumpTimeline(tester, ['a', 'b', 'c']);

    expect(opacityOf(tester, 'c'), lessThan(1));
    expect(opacityOf(tester, 'b'), 1);

    await tester.pump(AppDuration.standard);
    expect(opacityOf(tester, 'c'), 1);

    await pumpTimeline(tester, ['a', 'b', 'c']);
    expect(opacityOf(tester, 'c'), 1);
  });

  testWidgets('after the timeline shrinks, a re-used index animates again', (
    final tester,
  ) async {
    await pumpTimeline(tester, ['a', 'b']);
    await pumpTimeline(tester, ['a']);
    await tester.pumpAndSettle();
    await pumpTimeline(tester, ['a', 'fresh']);

    expect(opacityOf(tester, 'fresh'), lessThan(1));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'fresh'), 1);
  });
}
