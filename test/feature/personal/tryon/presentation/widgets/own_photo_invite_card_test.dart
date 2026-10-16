import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/own_photo_invite_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/own_photo_invite_card.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier(this._profile);

  final UserProfile _profile;

  @override
  Future<UserProfile?> build() async => _profile;
}

class _FakeAvatarUploadNotifier extends AvatarUploadNotifier {
  _FakeAvatarUploadNotifier(this._replacement);

  final PendingAvatar? _replacement;

  @override
  PendingAvatar? build() => _replacement;
}

class _FakeInviteDismissal extends OwnPhotoInviteDismissedNotifier {
  _FakeInviteDismissal(this._isDismissed);

  final bool _isDismissed;

  @override
  Future<bool> build() async => _isDismissed;
}

TryonSubject _generated(final TryonMode mode) => TryonSubject.generate(
  pieces: const [OutfitPiece.local(path: 'shirt.jpg')],
  mode: mode,
);

final _imageResult = FinishedTryonEntry(
  const TryonResult(id: 'img', mode: TryonMode.image, imageUrl: 'u'),
  _generated(TryonMode.image),
);

void main() {
  const title = '穿在你身上會是什麼樣子？';
  const preset = Avatar.preset(PresetAvatar.female);

  Future<void> pumpCard(
    final WidgetTester tester, {
    final TryonGalleryEntry? entry,
    final Avatar avatar = preset,
    final bool isTutorialCompleted = true,
    final PendingAvatar? replacement,
    final bool isDismissed = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
          avatarUploadProvider.overrideWith(
            () => _FakeAvatarUploadNotifier(replacement),
          ),
          ownPhotoInviteDismissedProvider.overrideWith(
            () => _FakeInviteDismissal(isDismissed),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OwnPhotoInviteCard(
              entry: entry ?? _imageResult,
              onUpload: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('invites a preset model on a finished photo try-on', (
    final tester,
  ) async {
    await pumpCard(tester);

    expect(find.text(title), findsOneWidget);
  });

  testWidgets('stays away once dismissed', (final tester) async {
    await pumpCard(tester, isDismissed: true);

    expect(find.text(title), findsNothing);
  });

  testWidgets('is absent when the model is your own photo', (
    final tester,
  ) async {
    await pumpCard(tester, avatar: const Avatar.uploaded('u1/avatar/me.jpg'));

    expect(find.text(title), findsNothing);
  });

  testWidgets('waits until the tutorial is completed', (final tester) async {
    await pumpCard(tester, isTutorialCompleted: false);

    expect(find.text(title), findsNothing);
  });

  testWidgets('hides while the model is being replaced', (final tester) async {
    await pumpCard(
      tester,
      replacement: const PendingAvatar.preset(PresetAvatar.male),
    );

    expect(find.text(title), findsNothing);
  });

  testWidgets('is absent while the try-on is still generating', (
    final tester,
  ) async {
    await pumpCard(
      tester,
      entry: PendingTryonEntry(id: 'p', subject: _generated(TryonMode.image)),
    );

    expect(find.text(title), findsNothing);
  });

  testWidgets('is absent on a video try-on', (final tester) async {
    await pumpCard(
      tester,
      entry: FinishedTryonEntry(
        const TryonResult(id: 'vid', mode: TryonMode.video, videoUrl: 'v'),
        _generated(TryonMode.video),
      ),
    );

    expect(find.text(title), findsNothing);
  });

  testWidgets('is absent on a video made from a try-on photo', (
    final tester,
  ) async {
    await pumpCard(
      tester,
      entry: FinishedTryonEntry(
        const TryonResult(id: 'anim', mode: TryonMode.video, videoUrl: 'v'),
        TryonSubject.animated(
          baseImageUrl: 'u',
          origin: _generated(TryonMode.image),
        ),
      ),
    );

    expect(find.text(title), findsNothing);
  });
}
