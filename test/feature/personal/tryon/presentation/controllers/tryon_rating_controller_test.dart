import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRatingRepository implements TryonRatingRepository {
  Failure? failure;
  Completer<void>? gate;
  final sent = <TryonRating?>[];

  @override
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonRating? rating,
  }) async {
    sent.add(rating);
    await gate?.future;
    if (failure case final failure?) return Err(failure);
    return const Ok(null);
  }
}

void main() {
  late _FakeRatingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRatingRepository();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        tryonRatingRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  TryonRatingController controller() =>
      container.read(tryonRatingControllerProvider.notifier);

  TryonRating? ratingOf(final String id) =>
      container.read(tryonRatingControllerProvider).ratings[id];

  test('tapping a rating stores it', () async {
    await controller().toggle('t1', TryonRating.like);

    expect(ratingOf('t1'), TryonRating.like);
    expect(repository.sent, [TryonRating.like]);
  });

  test('tapping the chosen rating again clears it', () async {
    await controller().toggle('t1', TryonRating.like);
    await controller().toggle('t1', TryonRating.like);

    expect(ratingOf('t1'), isNull);
    expect(repository.sent, [TryonRating.like, null]);
  });

  test('tapping the other rating switches to it', () async {
    await controller().toggle('t1', TryonRating.like);
    await controller().toggle('t1', TryonRating.dislike);

    expect(ratingOf('t1'), TryonRating.dislike);
  });

  test('ratings are kept per try-on', () async {
    await controller().toggle('t1', TryonRating.like);
    await controller().toggle('t2', TryonRating.dislike);

    expect(ratingOf('t1'), TryonRating.like);
    expect(ratingOf('t2'), TryonRating.dislike);
  });

  test('shows the new rating while it is being saved', () async {
    repository.gate = Completer<void>();

    final saving = controller().toggle('t1', TryonRating.like);

    expect(ratingOf('t1'), TryonRating.like);
    expect(
      container.read(tryonRatingControllerProvider).saving,
      contains('t1'),
    );
    repository.gate!.complete();
    await saving;
    expect(container.read(tryonRatingControllerProvider).saving, isEmpty);
  });

  test('a failed save restores the previous rating', () async {
    await controller().toggle('t1', TryonRating.like);
    repository.failure = const ServerFailure();

    final result = await controller().toggle('t1', TryonRating.dislike);

    expect(result.isFailure, isTrue);
    expect(ratingOf('t1'), TryonRating.like);
  });

  test('a tap while the last one is still saving is ignored', () async {
    repository.gate = Completer<void>();

    final first = controller().toggle('t1', TryonRating.like);
    await controller().toggle('t1', TryonRating.dislike);
    repository.gate!.complete();
    await first;

    expect(repository.sent, [TryonRating.like]);
    expect(ratingOf('t1'), TryonRating.like);
  });

  test(
    'a save that fails after the controller reset leaves the reset state alone',
    () async {
      await controller().toggle('t1', TryonRating.like);
      repository
        ..gate = Completer<void>()
        ..failure = const ServerFailure();

      final saving = controller().toggle('t1', TryonRating.dislike);
      container.invalidate(tryonRatingControllerProvider);
      container.read(tryonRatingControllerProvider);
      repository.gate!.complete();
      await saving;

      expect(
        container.read(tryonRatingControllerProvider),
        const TryonRatingState(),
      );
    },
  );
}
