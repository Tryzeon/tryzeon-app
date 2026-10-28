import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_image_editor.dart';

Future<void> _pumpEditor(
  final WidgetTester tester, {
  final List<ImageItem> images = const [],
  final ValueChanged<List<ImageItem>>? onImagesChanged,
  final bool hostsCoachMark = false,
  final bool showsCount = true,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProductImageEditor(
            images: images,
            onImagesChanged: onImagesChanged ?? (final _) {},
            onPickImage: () {},
            hasError: false,
            hostsCoachMark: hostsCoachMark,
            horizontalPadding: AppSpacing.lg,
            showsCount: showsCount,
          ),
        ),
      ),
    ),
  );
}

List<ImageItem> _photos(final int count) => [
  for (var i = 0; i < count; i++) ImageItem.newImage(file: File('$i.jpg')),
];

final _anchor = find.byWidgetPredicate(
  (final w) =>
      w is CoachMarkAnchor && w.target == CoachMarkTarget.productImages,
);

void main() {
  testWidgets('a tap beside the small remove badge still removes the photo', (
    final tester,
  ) async {
    List<ImageItem>? changed;
    await _pumpEditor(
      tester,
      images: _photos(1),
      onImagesChanged: (final images) => changed = images,
    );

    final badge = tester.getCenter(find.byIcon(Icons.close));
    await tester.tapAt(badge.translate(-12, 12));

    expect(changed, isEmpty);
  });

  testWidgets('the reorder hint appears once there are photos to reorder', (
    final tester,
  ) async {
    await _pumpEditor(tester, images: _photos(1));
    expect(find.text('長按照片拖曳調整順序'), findsNothing);
    expect(find.text('試穿主圖'), findsOneWidget);

    await _pumpEditor(tester, images: _photos(2));
    expect(find.text('長按照片拖曳調整順序'), findsOneWidget);
  });

  testWidgets('the photo count can be left to the host', (final tester) async {
    await _pumpEditor(tester, showsCount: false);

    expect(find.textContaining('照片'), findsNothing);
  });

  testWidgets('the empty add block is the image coach-mark target', (
    final tester,
  ) async {
    await _pumpEditor(tester, hostsCoachMark: true);

    final block = find.ancestor(
      of: find.text('點擊新增'),
      matching: find.byType(Container),
    );
    expect(tester.getRect(_anchor), tester.getRect(block.first));
  });

  testWidgets('an editor that does not host the coach mark has no anchor', (
    final tester,
  ) async {
    await _pumpEditor(tester, hostsCoachMark: false);

    expect(_anchor, findsNothing);
  });
}
