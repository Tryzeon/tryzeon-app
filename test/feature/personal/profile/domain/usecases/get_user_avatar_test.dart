import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_avatar.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements UserProfileRepository {
  final List<String> requested = [];

  @override
  Future<Result<File, Failure>> getUserAvatar(final String path) async {
    requested.add(path);
    return Ok(File(path));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakePresetAvatarSource implements PresetAvatarSource {
  final List<PresetAvatar> requested = [];

  @override
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset) async {
    requested.add(preset);
    return Ok(File('${preset.name}.jpg'));
  }
}

void main() {
  late _FakeRepository repository;
  late _FakePresetAvatarSource presetAvatarSource;
  late GetUserAvatar getUserAvatar;

  setUp(() {
    repository = _FakeRepository();
    presetAvatarSource = _FakePresetAvatarSource();
    getUserAvatar = GetUserAvatar(
      repository: repository,
      presetAvatarSource: presetAvatarSource,
    );
  });

  test('a preset is served by the preset source', () async {
    final result = await getUserAvatar(
      const Avatar.preset(PresetAvatar.female),
    );

    expect(result.get()!.path, 'female.jpg');
    expect(presetAvatarSource.requested, [PresetAvatar.female]);
    expect(repository.requested, isEmpty);
  });

  test('an uploaded photo is downloaded from storage', () async {
    final result = await getUserAvatar(
      const Avatar.uploaded('u1/avatar/me.jpg'),
    );

    expect(result.get()!.path, 'u1/avatar/me.jpg');
    expect(repository.requested, ['u1/avatar/me.jpg']);
    expect(presetAvatarSource.requested, isEmpty);
  });
}
