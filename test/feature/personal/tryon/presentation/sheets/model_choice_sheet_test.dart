import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/model_choice_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier(this._gender);

  final Gender? _gender;

  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    gender: _gender,
    isTutorialCompleted: true,
  );
}

void main() {
  const photoSourceTitle = '選擇模特來源';

  late List<PresetAvatar> applied;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1170, 2532);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Finder tileOf(final String title) =>
      find.widgetWithText(ModelChoiceTile, title);

  Future<void> open(
    final WidgetTester tester, {
    final PresetAvatar? current,
    final Gender? gender,
  }) async {
    applied = [];
    await openSheet<void>(
      tester,
      (final context) => ModelChoiceSheet.show(
        context: context,
        current: current,
        onPresetSelected: applied.add,
        onUploadOwnPhoto: () => showAppSheet<void>(
          context: context,
          builder: (final _) =>
              const AppSheet(title: photoSourceTitle, body: SizedBox.shrink()),
        ),
      ),
      overrides: [
        userProfileProvider.overrideWith(
          () => _FakeUserProfileNotifier(gender),
        ),
        presetAvatarFileProvider.overrideWith(
          (final ref, final preset) => Completer<File>().future,
        ),
      ],
    );
  }

  testWidgets('picking another preset applies it and closes', (
    final tester,
  ) async {
    await open(tester, current: PresetAvatar.female);

    await tester.tap(tileOf(PresetAvatar.male.label));
    await settle(tester);

    expect(find.byType(ModelChoiceSheet), findsNothing);
    expect(applied, [PresetAvatar.male]);
  });

  testWidgets('picking the preset already in use closes without applying', (
    final tester,
  ) async {
    await open(tester, current: PresetAvatar.female);

    expect(
      find.descendant(
        of: tileOf(PresetAvatar.female.label),
        matching: find.text('使用中'),
      ),
      findsOneWidget,
    );

    await tester.tap(tileOf(PresetAvatar.female.label));
    await settle(tester);

    expect(find.byType(ModelChoiceSheet), findsNothing);
    expect(applied, isEmpty);
  });

  testWidgets(
    'choosing upload closes the sheet before the photo source opens',
    (final tester) async {
      await open(tester, current: PresetAvatar.female);

      await tester.tap(tileOf('上傳全身照'));
      await settle(tester);

      expect(find.byType(ModelChoiceSheet), findsNothing);
      expect(find.text(photoSourceTitle), findsOneWidget);
      expect(applied, isEmpty);
    },
  );

  testWidgets('offers only the presets matching the gender', (
    final tester,
  ) async {
    await open(tester, gender: Gender.male);

    expect(tileOf(PresetAvatar.male.label), findsOneWidget);
    expect(tileOf(PresetAvatar.female.label), findsNothing);
    expect(tileOf('上傳全身照'), findsOneWidget);
  });

  testWidgets('swiping it away applies nothing', (final tester) async {
    await open(tester, current: PresetAvatar.female);

    await dismissByDrag(tester);

    expect(find.byType(ModelChoiceSheet), findsNothing);
    expect(applied, isEmpty);
  });
}
