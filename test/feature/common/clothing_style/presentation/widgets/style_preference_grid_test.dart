import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/clothing_style/presentation/widgets/style_preference_grid.dart';

void main() {
  testWidgets('shows every style image at its native 3:4 ratio, uncropped', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StylePreferenceGrid(selected: const {}, onToggle: (final _) {}),
        ),
      ),
    );

    final images = find.byType(Image);
    expect(images, findsWidgets);
    for (final image in images.evaluate()) {
      final size = tester.getSize(find.byWidget(image.widget));
      expect(size.width / size.height, closeTo(3 / 4, 0.01));
    }
    expect(
      tester.widget<Image>(images.first).fit,
      isNot(BoxFit.cover),
      reason: 'a matching box needs no crop',
    );
  });

  testWidgets('labels sit directly below their image', (final tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StylePreferenceGrid(selected: const {}, onToggle: (final _) {}),
        ),
      ),
    );

    final image = tester.getRect(find.byType(Image).first);
    final label = tester.getRect(find.text(ClothingStyle.basic.label));
    expect(label.top - image.bottom, closeTo(AppSpacing.sm, AppStroke.regular));
  });
}
