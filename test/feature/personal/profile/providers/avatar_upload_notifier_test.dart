import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/select_preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/upload_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    isTutorialCompleted: true,
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatar: const Avatar.uploaded('u1/avatar/old.jpg'),
  );
}

class _FakeUploadUserAvatar implements UploadUserAvatar {
  Completer<Result<void, Failure>>? pending;
  Object? thrown;
  final List<File> calls = [];

  @override
  Future<Result<void, Failure>> call(final File avatarFile) async {
    calls.add(avatarFile);
    if (thrown case final error?) throw error;
    return pending?.future ?? Future.value(const Ok(null));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeSelectPresetAvatar implements SelectPresetAvatar {
  Completer<Result<void, Failure>>? pending;
  Result<void, Failure> result = const Ok(null);
  final List<PresetAvatar> calls = [];

  @override
  Future<Result<void, Failure>> call(final PresetAvatar preset) {
    calls.add(preset);
    return pending?.future ?? Future.value(result);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeGetUserAvatar implements GetUserAvatar {
  Result<File, Failure> result = Ok(File('preset_male.jpg'));
  Completer<Result<File, Failure>>? pending;
  final List<Avatar> calls = [];

  @override
  Future<Result<File, Failure>> call(final Avatar avatar) {
    calls.add(avatar);
    return pending?.future ?? Future.value(result);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeUploadUserAvatar uploadUserAvatar;
  late _FakeSelectPresetAvatar selectPresetAvatar;
  late _FakeGetUserAvatar getUserAvatar;

  ProviderContainer makeContainer({
    final Future<File?> Function(Ref ref)? avatarFile,
  }) {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
        uploadUserAvatarUseCaseProvider.overrideWithValue(uploadUserAvatar),
        selectPresetAvatarUseCaseProvider.overrideWithValue(selectPresetAvatar),
        getUserAvatarUseCaseProvider.overrideWithValue(getUserAvatar),
        avatarFileProvider.overrideWith(
          avatarFile ?? (final ref) async => null,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(avatarUploadProvider, (final _, final _) {});
    container.listen(avatarFileProvider, (final _, final _) {});
    return container;
  }

  setUp(() {
    uploadUserAvatar = _FakeUploadUserAvatar();
    selectPresetAvatar = _FakeSelectPresetAvatar();
    getUserAvatar = _FakeGetUserAvatar();
  });

  test(
    'a failed avatar reload does not turn a saved upload into a failure',
    () async {
      final container = makeContainer(
        avatarFile: (final ref) async => throw const NetworkFailure(),
      );

      final result = await container
          .read(avatarUploadProvider.notifier)
          .upload(File('a.jpg'));

      expect(result.isSuccess, isTrue);
      expect(container.read(avatarUploadProvider), isNull);
    },
  );

  test('an own photo is uploaded as the avatar', () async {
    final container = makeContainer();

    await container.read(avatarUploadProvider.notifier).upload(File('me.jpg'));

    expect(uploadUserAvatar.calls.single.path, 'me.jpg');
    expect(selectPresetAvatar.calls, isEmpty);
  });

  test('a preset is selected, never uploaded', () async {
    final container = makeContainer();

    final result = await container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);

    expect(result.isSuccess, isTrue);
    expect(selectPresetAvatar.calls, [PresetAvatar.male]);
    expect(uploadUserAvatar.calls, isEmpty);
  });

  test('names the preset being applied until it is in place', () async {
    final container = makeContainer();
    selectPresetAvatar.pending = Completer();

    final applying = container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);

    expect(
      container.read(avatarUploadProvider),
      const PendingAvatar.preset(PresetAvatar.male),
    );

    selectPresetAvatar.pending!.complete(const Ok(null));
    await applying;
    expect(container.read(avatarUploadProvider), isNull);
  });

  test('names the photo being uploaded until it is in place', () async {
    final container = makeContainer();
    uploadUserAvatar.pending = Completer();
    final photo = File('me.jpg');

    final uploading = container
        .read(avatarUploadProvider.notifier)
        .upload(photo);

    expect(container.read(avatarUploadProvider), PendingAvatar.photo(photo));

    uploadUserAvatar.pending!.complete(const Ok(null));
    await uploading;
    expect(container.read(avatarUploadProvider), isNull);
  });

  test('applying a preset never fetches its image itself', () async {
    final container = makeContainer();

    await container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);

    expect(getUserAvatar.calls, isEmpty);
  });

  test('rejects a second replacement while one is in flight', () async {
    final container = makeContainer();
    uploadUserAvatar.pending = Completer();
    final notifier = container.read(avatarUploadProvider.notifier);

    final first = notifier.upload(File('me.jpg'));
    final second = await notifier.applyPreset(PresetAvatar.female);

    expect(second.getError(), isA<ValidationFailure>());
    expect(selectPresetAvatar.calls, isEmpty);

    uploadUserAvatar.pending!.complete(const Ok(null));
    expect((await first).isSuccess, isTrue);
    expect(container.read(avatarUploadProvider), isNull);
  });

  group('pendingAvatarPreview', () {
    File? preview(final ProviderContainer container) =>
        container.read(pendingAvatarPreviewProvider);

    test('is the photo being uploaded', () async {
      final container = makeContainer();
      container.listen(pendingAvatarPreviewProvider, (final _, final _) {});
      uploadUserAvatar.pending = Completer();

      final uploading = container
          .read(avatarUploadProvider.notifier)
          .upload(File('me.jpg'));

      expect(preview(container)?.path, 'me.jpg');

      uploadUserAvatar.pending!.complete(const Ok(null));
      await uploading;
      expect(preview(container), isNull);
    });

    test('is the preset image once it has downloaded', () async {
      final container = makeContainer();
      container.listen(pendingAvatarPreviewProvider, (final _, final _) {});
      getUserAvatar.pending = Completer();
      selectPresetAvatar.pending = Completer();

      final applying = container
          .read(avatarUploadProvider.notifier)
          .applyPreset(PresetAvatar.male);
      await Future<void>.delayed(Duration.zero);

      expect(preview(container), isNull);
      expect(selectPresetAvatar.calls, [PresetAvatar.male]);

      getUserAvatar.pending!.complete(Ok(File('preset_male.jpg')));
      await Future<void>.delayed(Duration.zero);
      expect(preview(container)?.path, 'preset_male.jpg');

      selectPresetAvatar.pending!.complete(const Ok(null));
      expect((await applying).isSuccess, isTrue);
      expect(preview(container), isNull);
    });

    test('stays empty when the preset image cannot be fetched, while the '
        'preset is still applied', () async {
      final container = makeContainer();
      container.listen(pendingAvatarPreviewProvider, (final _, final _) {});
      getUserAvatar.result = const Err(NetworkFailure());
      selectPresetAvatar.pending = Completer();

      final applying = container
          .read(avatarUploadProvider.notifier)
          .applyPreset(PresetAvatar.male);
      await Future<void>.delayed(Duration.zero);

      expect(preview(container), isNull);
      expect(container.read(avatarUploadProvider), isNotNull);

      selectPresetAvatar.pending!.complete(const Ok(null));
      expect((await applying).isSuccess, isTrue);
      expect(selectPresetAvatar.calls, [PresetAvatar.male]);
    });
  });

  test(
    'no longer busy once a replacement fails, so another can start',
    () async {
      final container = makeContainer();
      selectPresetAvatar.result = const Err(NetworkFailure());
      final notifier = container.read(avatarUploadProvider.notifier);

      final failed = await notifier.applyPreset(PresetAvatar.male);

      expect(failed.getError(), isA<NetworkFailure>());
      expect(container.read(avatarUploadProvider), isNull);
      expect((await notifier.upload(File('me.jpg'))).isSuccess, isTrue);
    },
  );

  test(
    'no longer busy once a replacement throws, so another can start',
    () async {
      final container = makeContainer();
      uploadUserAvatar.thrown = StateError('boom');
      final notifier = container.read(avatarUploadProvider.notifier);

      final failed = await notifier.upload(File('me.jpg'));

      expect(failed.isFailure, isTrue);
      expect(container.read(avatarUploadProvider), isNull);
      expect((await notifier.applyPreset(PresetAvatar.male)).isSuccess, isTrue);
    },
  );
}
