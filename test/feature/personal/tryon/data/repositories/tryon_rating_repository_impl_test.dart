import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_rating_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_rating_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements TryonRatingRemoteDataSource {
  _FakeRemote({this.error});

  final Object? error;
  final calls = <String>[];

  @override
  Future<void> upsert({
    required final String tryonId,
    required final String rating,
  }) async {
    calls.add('upsert $tryonId $rating');
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
  test('a rating is stored by its wire value', () async {
    final remote = _FakeRemote();

    final result = await TryonRatingRepositoryImpl(
      remoteDataSource: remote,
    ).rate(tryonId: 't1', rating: TryonRating.dislike);

    expect(result.isSuccess, isTrue);
    expect(remote.calls, ['upsert t1 dislike']);
  });

  test('a null rating clears the stored one', () async {
    final remote = _FakeRemote();

    final result = await TryonRatingRepositoryImpl(
      remoteDataSource: remote,
    ).rate(tryonId: 't1', rating: null);

    expect(result.isSuccess, isTrue);
    expect(remote.calls, ['delete t1']);
  });

  test('a database error is a server failure', () async {
    final result = await TryonRatingRepositoryImpl(
      remoteDataSource: _FakeRemote(
        error: const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      ),
    ).rate(tryonId: 't1', rating: TryonRating.like);

    expect(result.getError(), isA<ServerFailure>());
  });
}
