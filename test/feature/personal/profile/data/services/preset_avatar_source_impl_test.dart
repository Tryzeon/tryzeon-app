import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/profile/data/services/preset_avatar_source_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:typed_result/typed_result.dart';

class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(final String key) => throw FlutterError('missing $key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('preset_avatar_test');
    addTearDown(() => tempDir.delete(recursive: true));
  });

  for (final preset in PresetAvatar.values) {
    test(
      'writes the bundled ${preset.name} preset to an uploadable jpg',
      () async {
        final source = PresetAvatarSourceImpl(
          bundle: rootBundle,
          temporaryDirectory: () async => tempDir,
        );

        final file = (await source.fileFor(preset)).get()!;

        final asset = await rootBundle.load(preset.assetPath);
        expect(file.path, endsWith('.jpg'));
        expect(await file.readAsBytes(), asset.buffer.asUint8List());
      },
    );
  }

  test('a missing asset is a failure, not a throw', () async {
    final source = PresetAvatarSourceImpl(
      bundle: _MissingAssetBundle(),
      temporaryDirectory: () async => tempDir,
    );

    final result = await source.fileFor(PresetAvatar.female);

    expect(result.isFailure, isTrue);
  });
}
