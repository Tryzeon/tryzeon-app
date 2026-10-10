import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRatingRepository implements TryonRatingRepository {
  Failure? failure;
  Completer<void>? gate;
  final sent = <TryonFeedback?>[];

  @override
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonFeedback? feedback,
  }) async {
    sent.add(feedback);
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

  TryonFeedback? feedbackOf(final String id) =>
      container.read(tryonRatingControllerProvider).feedback[id];

  const like = TryonFeedback.like();
  const dislike = TryonFeedback.dislike();

  test('tapping a rating stores it', () async {
    await controller().toggle('t1', like);

    expect(feedbackOf('t1'), like);
    expect(repository.sent, [like]);
  });

  test('tapping the chosen rating again clears it', () async {
    await controller().toggle('t1', like);
    await controller().toggle('t1', like);

    expect(feedbackOf('t1'), isNull);
    expect(repository.sent, [like, null]);
  });

  test('tapping the other rating switches to it', () async {
    await controller().toggle('t1', like);
    await controller().toggle('t1', dislike);

    expect(feedbackOf('t1'), dislike);
  });

  test('ratings are kept per try-on', () async {
    await controller().toggle('t1', like);
    await controller().toggle('t2', dislike);

    expect(feedbackOf('t1'), like);
    expect(feedbackOf('t2'), dislike);
  });

  test('shows the new rating while it is being saved', () async {
    repository.gate = Completer<void>();

    final saving = controller().toggle('t1', like);

    expect(feedbackOf('t1'), like);
    expect(
      container.read(tryonRatingControllerProvider).saving,
      contains('t1'),
    );
    repository.gate!.complete();
    await saving;
    expect(container.read(tryonRatingControllerProvider).saving, isEmpty);
  });

  test('a failed save restores the previous rating', () async {
    await controller().toggle('t1', like);
    repository.failure = const ServerFailure();

    final result = await controller().toggle('t1', dislike);

    expect(result.isFailure, isTrue);
    expect(feedbackOf('t1'), like);
  });

  test('a tap while the last one is still saving is ignored', () async {
    repository.gate = Completer<void>();

    final first = controller().toggle('t1', like);
    await controller().toggle('t1', dislike);
    repository.gate!.complete();
    await first;

    expect(repository.sent, [like]);
    expect(feedbackOf('t1'), like);
  });

  test(
    'a save that fails after the controller reset leaves the reset state alone',
    () async {
      await controller().toggle('t1', like);
      repository
        ..gate = Completer<void>()
        ..failure = const ServerFailure();

      final saving = controller().toggle('t1', dislike);
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

  group('explaining a dislike', () {
    const deformed = TryonDislike(reason: TryonDislikeReason.garmentDeformed);
    const typed = TryonDislike(comment: '袖子不見了');

    test('a picked reason is saved with the dislike', () async {
      await controller().toggle('t1', dislike);

      await controller().explain('t1', deformed);

      expect(feedbackOf('t1'), deformed);
      expect(repository.sent.last, deformed);
    });

    test('typed words are saved with the dislike', () async {
      await controller().toggle('t1', dislike);

      await controller().explain('t1', typed);

      expect(feedbackOf('t1'), typed);
      expect(repository.sent.last, typed);
    });

    test('an explanation is ignored unless the try-on is disliked', () async {
      await controller().toggle('t1', like);

      await controller().explain('t1', deformed);

      expect(feedbackOf('t1'), like);
      expect(repository.sent, [like]);
    });

    test('switching to a like drops the explanation', () async {
      await controller().toggle('t1', dislike);
      await controller().explain('t1', deformed);

      await controller().toggle('t1', like);

      expect(feedbackOf('t1'), like);
      expect(repository.sent.last, like);
    });

    test('disliking again starts unexplained', () async {
      await controller().toggle('t1', dislike);
      await controller().explain('t1', deformed);
      await controller().toggle('t1', dislike);

      await controller().toggle('t1', dislike);

      expect(feedbackOf('t1'), dislike);
    });

    test(
      'an explanation while the dislike is still saving is ignored',
      () async {
        repository.gate = Completer<void>();
        final rating = controller().toggle('t1', dislike);

        await controller().explain('t1', deformed);
        repository.gate!.complete();
        await rating;

        expect(feedbackOf('t1'), dislike);
        expect(repository.sent, [dislike]);
      },
    );

    test('a rating tap while an explanation saves is ignored', () async {
      await controller().toggle('t1', dislike);
      repository.gate = Completer<void>();
      final explaining = controller().explain('t1', deformed);

      await controller().toggle('t1', like);
      repository.gate!.complete();
      await explaining;

      expect(feedbackOf('t1'), deformed);
    });

    test('a failed explanation leaves the dislike unexplained', () async {
      await controller().toggle('t1', dislike);
      repository.failure = const ServerFailure();

      final result = await controller().explain('t1', deformed);

      expect(result.isFailure, isTrue);
      expect(feedbackOf('t1'), dislike);
    });
  });
}
