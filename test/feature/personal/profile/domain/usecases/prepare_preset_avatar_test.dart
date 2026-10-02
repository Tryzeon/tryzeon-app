import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/prepare_preset_avatar.dart';
import 'package:typed_result/typed_result.dart';

class _FakePresetAvatarSource implements PresetAvatarSource {
  Result<File, Failure> result = Ok(File('preset_female.jpg'));
  final List<PresetAvatar> requested = [];

  @override
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset) async {
    requested.add(preset);
    return result;
  }
}

void main() {
  late _FakePresetAvatarSource source;
  late PreparePresetAvatar preparePresetAvatar;

  setUp(() {
    source = _FakePresetAvatarSource();
    preparePresetAvatar = PreparePresetAvatar(source);
  });

  test('hands back an uploadable file for the chosen preset', () async {
    final result = await preparePresetAvatar(PresetAvatar.female);

    expect(source.requested, [PresetAvatar.female]);
    expect(result.get()!.path, 'preset_female.jpg');
  });

  test('a preset that cannot be prepared is a failure', () async {
    source.result = const Err(UnknownFailure());

    final result = await preparePresetAvatar(PresetAvatar.female);

    expect(result.getError(), const UnknownFailure());
  });
}
