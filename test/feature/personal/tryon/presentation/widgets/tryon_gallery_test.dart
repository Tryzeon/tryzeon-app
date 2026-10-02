import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery.dart';

void main() {
  Future<void> pumpGallery(final WidgetTester tester, {final bool showScrims = true}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TryonGallery(
            pageController: PageController(),
            onPageChanged: (final _) {},
            entries: const [],
            avatarPage: const SizedBox.expand(),
            showScrims: showScrims,
          ),
        ),
      ),
    );
  }

  testWidgets('the scrims are only drawn when asked for', (final tester) async {
    bool hasGradient(final Widget w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).gradient != null;

    await pumpGallery(tester, showScrims: false);
    expect(find.byWidgetPredicate(hasGradient), findsNothing);

    await pumpGallery(tester);
    expect(find.byWidgetPredicate(hasGradient), findsNWidgets(2));
  });
}
