import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/prefetch_preset_avatars.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakePrefetchPresetAvatars implements PrefetchPresetAvatars {
  Result<void, Failure> result = const Ok(null);
  final List<Gender?> calls = [];

  @override
  Future<Result<void, Failure>> call(final Gender? gender) async {
    calls.add(gender);
    return result;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakePrefetchPresetAvatars prefetchPresetAvatars;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        prefetchPresetAvatarsUseCaseProvider.overrideWithValue(
          prefetchPresetAvatars,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    prefetchPresetAvatars = _FakePrefetchPresetAvatars();
  });

  test('prefetches the presets for the gender it is keyed by', () async {
    final container = makeContainer();

    await container.read(presetAvatarsPrefetchProvider(Gender.female).future);

    expect(prefetchPresetAvatars.calls, [Gender.female]);
  });

  test('a failed prefetch is only logged, never surfaced', () async {
    AppLogger.talker.cleanHistory();
    prefetchPresetAvatars.result = const Err(NetworkFailure());
    final container = makeContainer();

    await expectLater(
      container.read(presetAvatarsPrefetchProvider(Gender.female).future),
      completes,
    );
    expect(
      AppLogger.talker.history.where(
        (final log) =>
            log.logLevel == LogLevel.warning &&
            (log.message ?? '').contains('preset avatars'),
      ),
      hasLength(1),
    );
  });
}
