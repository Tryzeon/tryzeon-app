import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/personal/profile/data/services/preset_avatar_source_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:typed_result/typed_result.dart';

class _FakeImageFileCache implements ImageFileCache {
  final List<(String, String?)> requests = [];
  Object? error;

  @override
  Future<File?> getImage(
    final String filePath, {
    final String? downloadUrl,
  }) async {
    requests.add((filePath, downloadUrl));
    if (error case final error?) throw error;
    return File('cache/$filePath');
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeImageFileCache imageFileCache;
  late PresetAvatarSourceImpl source;

  setUp(() {
    imageFileCache = _FakeImageFileCache();
    source = PresetAvatarSourceImpl(imageFileCache);
  });

  for (final preset in PresetAvatar.values) {
    test(
      'serves the ${preset.name} preset from the public images bucket',
      () async {
        final key = 'presets/${preset.name}.jpg';

        final file = (await source.fileFor(preset)).get()!;

        expect(file.path, 'cache/$key');
        expect(imageFileCache.requests, [(key, PublicImageUrl.of(key))]);
      },
    );
  }

  test('an unreachable preset image is a failure, not a throw', () async {
    imageFileCache.error = const SocketException('offline');

    final result = await source.fileFor(PresetAvatar.female);

    expect(result.getError(), const NetworkFailure());
  });
}
