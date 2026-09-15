import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/measurement_guide_sheet.dart';

void main() {
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
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsNothing);
  });

  testWidgets('dress pages through two guides with an indicator', (final tester) async {
    await pumpSheet(tester, GarmentType.dress);

    expect(find.text('連身測量方式'), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsOneWidget);

    final topGuide = find.image(const AssetImage('assets/images/size_guide/top.webp'));
    final pantsGuide = find.image(
      const AssetImage('assets/images/size_guide/pants.webp'),
    );
    expect(topGuide, findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(pantsGuide, findsOneWidget);
  });
}
