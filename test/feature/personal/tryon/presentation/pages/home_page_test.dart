import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/model_choice_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_page.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile?> build() async => _profile;
}

class _RecordingAvatarUpload extends AvatarUploadNotifier {
  _RecordingAvatarUpload(this._replacement);

  final PendingAvatar? _replacement;
  final applied = <PresetAvatar>[];

  @override
  PendingAvatar? build() => _replacement;

  @override
  Future<Result<void, Failure>> applyPreset(final PresetAvatar preset) async {
    applied.add(preset);
    return const Ok(null);
  }
}

void main() {
  const photoSourceTitle = '選擇模特來源';

  late _RecordingAvatarUpload avatarUpload;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1170, 2532);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  Finder tileOf(final String title) =>
      find.widgetWithText(ModelChoiceTile, title);

  Future<void> pumpHome(
    final WidgetTester tester, {
    required final Avatar avatar,
    final bool isTutorialCompleted = true,
    final PendingAvatar? replacement,
  }) async {
    avatarUpload = _RecordingAvatarUpload(replacement);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          userProfileProvider.overrideWith(
            () => _FakeUserProfileNotifier(
              UserProfile(
                userId: 'u1',
                name: 'n',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                avatar: avatar,
                isTutorialCompleted: isTutorialCompleted,
              ),
            ),
          ),
          avatarFileProvider.overrideWith(
            (final ref) async => File('model.jpg'),
          ),
          avatarUploadProvider.overrideWith(() => avatarUpload),
          presetAvatarFileProvider.overrideWith(
            (final ref, final preset) => Completer<File>().future,
          ),
          subscriptionCapabilitiesProvider.overrideWith(
            (final ref) async => const SubscriptionCapabilities(
              wardrobeLimit: 10,
              dailyTryonLimit: 10,
              dailyChatLimit: 10,
              dailyVideoLimit: 0,
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
      ),
    );
    await settle(tester);
  }

  Future<void> tapModelPhoto(final WidgetTester tester) async {
    await tester.tap(find.byType(TryonAvatarPage));
    await settle(tester);
  }

  testWidgets(
    'the menu opens the model choice with the current preset marked',
    (final tester) async {
      await pumpHome(tester, avatar: const Avatar.preset(PresetAvatar.female));

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await settle(tester);
      await tester.tap(find.text('更換模特圖片'));
      await settle(tester);

      expect(find.byType(ModelChoiceSheet), findsOneWidget);
      expect(
        find.descendant(
          of: tileOf(PresetAvatar.female.label),
          matching: find.text('使用中'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping your own photo opens the model choice, nothing marked', (
    final tester,
  ) async {
    await pumpHome(tester, avatar: const Avatar.uploaded('u1/avatar/me.jpg'));

    await tapModelPhoto(tester);

    expect(find.byType(ModelChoiceSheet), findsOneWidget);
    expect(find.text('使用中'), findsNothing);
  });

  testWidgets('picking another preset in the model choice applies it', (
    final tester,
  ) async {
    await pumpHome(tester, avatar: const Avatar.preset(PresetAvatar.female));
    await tapModelPhoto(tester);

    await tester.tap(tileOf(PresetAvatar.male.label));
    await settle(tester);

    expect(find.byType(ModelChoiceSheet), findsNothing);
    expect(avatarUpload.applied, [PresetAvatar.male]);
  });

  testWidgets(
    'uploading from the model choice closes it, then asks the source',
    (final tester) async {
      await pumpHome(tester, avatar: const Avatar.preset(PresetAvatar.female));
      await tapModelPhoto(tester);

      await tester.tap(tileOf('上傳全身照'));
      await settle(tester);

      expect(find.byType(ModelChoiceSheet), findsNothing);
      expect(find.text(photoSourceTitle), findsOneWidget);
    },
  );

  testWidgets(
    'while a preset is being applied, the model photo does not reopen the '
    'model choice',
    (final tester) async {
      await pumpHome(
        tester,
        avatar: const Avatar.preset(PresetAvatar.female),
        replacement: const PendingAvatar.preset(PresetAvatar.male),
      );

      await tapModelPhoto(tester);

      expect(find.byType(ModelChoiceSheet), findsNothing);
    },
  );
}
