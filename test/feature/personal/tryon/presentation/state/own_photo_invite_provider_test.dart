import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/own_photo_invite_provider.dart';
import 'package:typed_result/typed_result.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.stored);

  Result<bool, Failure> stored;
  var dismissCount = 0;

  @override
  Future<Result<bool, Failure>> isOwnPhotoInviteDismissed() async => stored;

  @override
  Future<Result<void, Failure>> dismissOwnPhotoInvite() async {
    dismissCount++;
    stored = const Ok(true);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier(this._avatar);

  final Avatar _avatar;

  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatar: _avatar,
    isTutorialCompleted: true,
  );

  void switchTo(final Avatar avatar) =>
      state = AsyncData(state.value!.copyWith(avatar: avatar));
}

void main() {
  const preset = Avatar.preset(PresetAvatar.female);
  const ownPhoto = Avatar.uploaded('u1/avatar/me.jpg');

  late _FakeSettingsRepository repository;
  late _FakeUserProfileNotifier profile;

  Future<ProviderContainer> containerWith({
    required final Result<bool, Failure> stored,
    final Avatar avatar = preset,
  }) async {
    repository = _FakeSettingsRepository(stored);
    profile = _FakeUserProfileNotifier(avatar);
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        userProfileProvider.overrideWith(() => profile),
      ],
    );
    addTearDown(container.dispose);
    container.listen(ownPhotoInviteDismissedProvider, (_, _) {});
    await container.read(userProfileProvider.future);
    return container;
  }

  test('reads the stored dismissal', () async {
    final container = await containerWith(stored: const Ok(false));

    expect(await container.read(ownPhotoInviteDismissedProvider.future), false);
  });

  test('an unreadable store reads as dismissed', () async {
    final container = await containerWith(stored: const Err(UnknownFailure()));

    expect(await container.read(ownPhotoInviteDismissedProvider.future), true);
  });

  test('dismissing hides it and persists the choice', () async {
    final container = await containerWith(stored: const Ok(false));
    await container.read(ownPhotoInviteDismissedProvider.future);

    await container.read(ownPhotoInviteDismissedProvider.notifier).dismiss();

    expect(container.read(ownPhotoInviteDismissedProvider).value, true);
    expect(repository.dismissCount, 1);
  });

  test('re-reads the stored flag when the avatar changes', () async {
    final container = await containerWith(stored: const Ok(false));
    expect(await container.read(ownPhotoInviteDismissedProvider.future), false);

    repository.stored = const Ok(true);
    profile.switchTo(ownPhoto);
    expect(await container.read(ownPhotoInviteDismissedProvider.future), true);

    profile.switchTo(preset);
    expect(await container.read(ownPhotoInviteDismissedProvider.future), true);
  });
}
