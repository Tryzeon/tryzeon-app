import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/share_tryon_media.dart';
import 'package:typed_result/typed_result.dart';

class _FakeMediaRepository implements TryonMediaRepository {
  final shared = <(String, TryonMode)>[];

  @override
  Future<Result<void, Failure>> share({
    required final String url,
    required final TryonMode mode,
  }) async {
    shared.add((url, mode));
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeMediaRepository repository;

  setUp(() => repository = _FakeMediaRepository());

  test('a video result shares its video', () async {
    await ShareTryonMedia(mediaRepository: repository)(
      const TryonResult(
        id: 't1',
        mode: TryonMode.video,
        imageUrl: 'https://cdn/t1.jpg',
        videoUrl: 'https://cdn/t1.mp4',
      ),
    );

    expect(repository.shared, [('https://cdn/t1.mp4', TryonMode.video)]);
  });

  test('a result missing its media is rejected without sharing', () async {
    final result = await ShareTryonMedia(mediaRepository: repository)(
      const TryonResult(id: 't1', mode: TryonMode.video),
    );

    expect(result.getError(), isA<ValidationFailure>());
    expect(repository.shared, isEmpty);
  });
}
