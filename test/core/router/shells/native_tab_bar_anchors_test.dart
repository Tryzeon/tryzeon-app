import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/shells/native_tab_bar_anchors.dart';

void main() {
  testWidgets('anchors a tab over its slot of the native bar on an iPhone 17', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Stack(
            children: [
              Positioned.fill(child: GestureDetector(onTap: () => taps++)),
              const Positioned.fill(
                child: NativeTabBarAnchors(
                  anchors: [null, CoachMarkTarget.shopTab, null, null, null],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final slot = tester.getRect(find.byType(CoachMarkAnchor));
    expect(slot.left, moreOrLessEquals(21 + 8 + 68.8));
    expect(slot.width, moreOrLessEquals(68.8));
    expect(slot.bottom, moreOrLessEquals(874 - 22));
    expect(slot.height, moreOrLessEquals(61));

    await tester.tapAt(slot.center);
    expect(taps, 1);
  });
}
