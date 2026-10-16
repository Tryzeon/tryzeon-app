import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:typed_result/typed_result.dart';

class PrefetchPresetAvatars {
  PrefetchPresetAvatars(this._presetAvatarSource);

  final PresetAvatarSource _presetAvatarSource;

  Future<Result<void, Failure>> call(final Gender? gender) async {
    final results = await Future.wait(
      PresetAvatar.forGender(gender).map(_presetAvatarSource.fileFor),
    );
    for (final result in results) {
      if (result case Err(:final error)) return Err(error);
    }
    return const Ok(null);
  }
}
