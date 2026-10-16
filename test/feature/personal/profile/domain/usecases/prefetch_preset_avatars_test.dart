import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/prefetch_preset_avatars.dart';
import 'package:typed_result/typed_result.dart';

class _FakePresetAvatarSource implements PresetAvatarSource {
  final List<PresetAvatar> requested = [];
  final Set<PresetAvatar> failing = {};

  @override
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset) async {
    requested.add(preset);
    if (failing.contains(preset)) return const Err(NetworkFailure());
    return Ok(File('${preset.name}.jpg'));
  }
}

void main() {
  late _FakePresetAvatarSource presetAvatarSource;
  late PrefetchPresetAvatars prefetchPresetAvatars;

  setUp(() {
    presetAvatarSource = _FakePresetAvatarSource();
    prefetchPresetAvatars = PrefetchPresetAvatars(presetAvatarSource);
  });

  test('fetches only the presets offered for the gender', () async {
    final result = await prefetchPresetAvatars(Gender.male);

    expect(result.isSuccess, isTrue);
    expect(presetAvatarSource.requested, [PresetAvatar.male]);
  });

  test('fetches every preset when the gender is unknown', () async {
    await prefetchPresetAvatars(null);

    expect(presetAvatarSource.requested, unorderedEquals(PresetAvatar.values));
  });

  test('one failed preset fails the prefetch but the rest still run', () async {
    presetAvatarSource.failing.add(PresetAvatar.female);

    final result = await prefetchPresetAvatars(null);

    expect(result.getError(), const NetworkFailure());
    expect(presetAvatarSource.requested, unorderedEquals(PresetAvatar.values));
  });
}
