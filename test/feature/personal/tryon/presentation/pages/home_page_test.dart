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
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/model_choice_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/own_photo_invite_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_page.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _InactiveTutorial extends TutorialController {
  @override
  TutorialState build() => const TutorialState.inactive();
}

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

class _FakeGallery extends TryonGalleryNotifier {
  _FakeGallery(this._initial);

  final TryonGalleryState _initial;

  @override
  TryonGalleryState build() => _initial;
}

class _RecordingInviteDismissal extends OwnPhotoInviteDismissedNotifier {
  var dismissCount = 0;

  @override
  Future<bool> build() async => false;

  @override
  Future<void> dismiss() async {
    dismissCount++;
    state = const AsyncData(true);
  }
}

final _imageResult = FinishedTryonEntry(
  const TryonResult(id: 'img', mode: TryonMode.image, imageUrl: 'u'),
  TryonSubject(
    pieces: const [OutfitPiece.local(path: 'shirt.jpg')],
    mode: TryonMode.image,
  ),
);

TryonGalleryState _showing(final TryonGalleryEntry entry) =>
    TryonGalleryState(entries: [entry], currentId: entry.id);

void main() {
  const photoSourceTitle = '選擇模特來源';
  const presetTag = '預設模特';
  const inviteTitle = '穿在你身上會是什麼樣子？';
  const preset = Avatar.preset(PresetAvatar.female);
  const ownPhoto = Avatar.uploaded('u1/avatar/me.jpg');

  late _RecordingAvatarUpload avatarUpload;
  late _RecordingInviteDismissal inviteDismissal;

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
    final PendingAvatar? replacement,
    final TryonGalleryState gallery = const TryonGalleryState(),
  }) async {
    avatarUpload = _RecordingAvatarUpload(replacement);
    inviteDismissal = _RecordingInviteDismissal();
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
                isTutorialCompleted: true,
              ),
            ),
          ),
          tutorialControllerProvider.overrideWith(_InactiveTutorial.new),
          avatarFileProvider.overrideWith(
            (final ref) async => File('model.jpg'),
          ),
          avatarUploadProvider.overrideWith(() => avatarUpload),
          tryonGalleryProvider.overrideWith(
            () => _FakeGallery(TryonGalleryState(entries: gallery.entries)),
          ),
          ownPhotoInviteDismissedProvider.overrideWith(() => inviteDismissal),
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

    // The page view only follows the gallery once attached, so open the page
    // in view after the first frame, as a swipe would.
    ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    ).read(tryonGalleryProvider.notifier).setCurrentPage(gallery.currentPage);
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

  group('preset tag', () {
    testWidgets('marks a preset model on the model page', (final tester) async {
      await pumpHome(tester, avatar: preset);

      expect(find.text(presetTag), findsOneWidget);
    });

    testWidgets('is absent once the model is your own photo', (
      final tester,
    ) async {
      await pumpHome(tester, avatar: ownPhoto);

      expect(find.text(presetTag), findsNothing);
    });

    testWidgets('hides while the model is being replaced', (
      final tester,
    ) async {
      await pumpHome(
        tester,
        avatar: preset,
        replacement: const PendingAvatar.preset(PresetAvatar.male),
      );

      expect(find.text(presetTag), findsNothing);
    });
  });

  group('own-photo invite', () {
    testWidgets('appears on a finished image try-on of a preset model', (
      final tester,
    ) async {
      await pumpHome(tester, avatar: preset, gallery: _showing(_imageResult));

      expect(find.text(inviteTitle).hitTestable(), findsOneWidget);
    });

    testWidgets('uploading from it asks for the photo source', (
      final tester,
    ) async {
      await pumpHome(tester, avatar: preset, gallery: _showing(_imageResult));

      await tester.tap(find.widgetWithText(FilledButton, '上傳全身照'));
      await settle(tester);

      expect(find.text(photoSourceTitle), findsOneWidget);
      expect(find.byType(ModelChoiceSheet), findsNothing);
    });

    testWidgets('closing it remembers the dismissal and hides it', (
      final tester,
    ) async {
      await pumpHome(tester, avatar: preset, gallery: _showing(_imageResult));

      await tester.tap(find.byTooltip('關閉'));
      await settle(tester);

      expect(inviteDismissal.dismissCount, 1);
      expect(find.text(inviteTitle), findsNothing);
    });
  });
}
