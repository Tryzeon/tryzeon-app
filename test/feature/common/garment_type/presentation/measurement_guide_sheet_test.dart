import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/measurement_guide_sheet.dart';

void main() {
  Finder findGuide(final String asset) => find.byWidgetPredicate(
    (final widget) => widget is PhotoView && widget.imageProvider == AssetImage(asset),
  );

  Future<void> pumpSheet(final WidgetTester tester, final GarmentType type) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MeasurementGuideSheet(garmentType: type)),
      ),
    );
    await tester.pump();
  }

  testWidgets('single-guide type shows one image and no page indicator', (
    final tester,
  ) async {
    await pumpSheet(tester, GarmentType.pants);

    expect(find.text('褲子測量方式'), findsOneWidget);
    expect(find.byType(PhotoView), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsNothing);
  });

  testWidgets('one_piece pages through two guides with an indicator', (
    final tester,
  ) async {
    await pumpSheet(tester, GarmentType.onePiece);

    expect(find.text('連身測量方式'), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsOneWidget);

    expect(findGuide('assets/images/size_guide/top.webp'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pump(const Duration(seconds: 1));

    expect(findGuide('assets/images/size_guide/pants.webp'), findsOneWidget);
  });

  testWidgets('a zoomed guide pans instead of flipping the page', (final tester) async {
    await pumpSheet(tester, GarmentType.dress);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/size_guide/top.webp'),
        tester.element(find.byType(PageView)),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final center = tester.getCenter(find.byType(PageView));

    final left = await tester.startGesture(center - const Offset(20, 0));
    final right = await tester.startGesture(center + const Offset(20, 0));
    await tester.pump();
    await left.moveBy(const Offset(-60, 0));
    await right.moveBy(const Offset(60, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pump(const Duration(seconds: 1));

    await tester.drag(find.byType(PageView), const Offset(-150, 0));
    await tester.pump(const Duration(seconds: 1));

    expect(findGuide('assets/images/size_guide/top.webp'), findsOneWidget);
    expect(findGuide('assets/images/size_guide/pants.webp'), findsNothing);
  });
}
