import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/pages/personal_onboarding_page.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

void main() {
  late List<Gender?> prefetched;

  Future<void> pumpPage(final WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetAvatarsPrefetchProvider.overrideWith((final ref, final gender) {
          prefetched.add(gender);
          return Future<void>.value();
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PersonalOnboardingPage(),
      ),
    ),
  );

  setUp(() {
    prefetched = [];
  });

  testWidgets('prefetches nothing before a gender is chosen', (
    final tester,
  ) async {
    await pumpPage(tester);

    expect(prefetched, isEmpty);
  });

  testWidgets('choosing a gender prefetches the presets offered for it', (
    final tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text(Gender.female.label));
    await tester.pump();

    expect(prefetched, [Gender.female]);
  });
}
