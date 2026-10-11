import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_rating_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_rating_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_rating_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements TryonRatingRemoteDataSource {
  _FakeRemote({this.error});

  final Object? error;
  final calls = <Object>[];

  @override
  Future<void> upsert(final TryonRatingRequest request) async {
    calls.add(request.toJson());
    if (error case final error?) throw error;
  }

  @override
  Future<void> delete(final String tryonId) async {
    calls.add('delete $tryonId');
    if (error case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  Future<(Result<void, Failure>, List<Object>)> rate(
    final TryonFeedback? feedback, {
    final Object? error,
  }) async {
    final remote = _FakeRemote(error: error);
    final result = await TryonRatingRepositoryImpl(
      remoteDataSource: remote,
    ).rate(tryonId: 't1', feedback: feedback);
    return (result, remote.calls);
  }

  test('a like is stored with no reasons', () async {
    final (result, calls) = await rate(const TryonFeedback.like());

    expect(result.isSuccess, isTrue);
    expect(calls, [
      {
        'tryon_generation_id': 't1',
        'rating': 'like',
        'reason': null,
        'comment': null,
      },
    ]);
  });

  test('a dislike is stored with the reason picked for it', () async {
    final (_, calls) = await rate(
      const TryonFeedback.dislike(reason: TryonDislikeReason.garmentDeformed),
    );

    expect(calls, [
      {
        'tryon_generation_id': 't1',
        'rating': 'dislike',
        'reason': 'garment_deformed',
        'comment': null,
      },
    ]);
  });

  test('a dislike is stored with the words typed for it', () async {
    final (_, calls) = await rate(
      const TryonFeedback.dislike(comment: '袖子不見了'),
    );

    expect(calls, [
      {
        'tryon_generation_id': 't1',
        'rating': 'dislike',
        'reason': null,
        'comment': '袖子不見了',
      },
    ]);
  });

  test('no feedback clears the stored one', () async {
    final (result, calls) = await rate(null);

    expect(result.isSuccess, isTrue);
    expect(calls, ['delete t1']);
  });

  test('a database error is a server failure', () async {
    final (result, _) = await rate(
      const TryonFeedback.like(),
      error: const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      ),
    );

    expect(result.getError(), isA<ServerFailure>());
  });
}
