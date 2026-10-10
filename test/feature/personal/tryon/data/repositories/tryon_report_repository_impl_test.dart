import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_report_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_report_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements TryonReportRemoteDataSource {
  _FakeRemote({this.error});

  final Object? error;
  final reported = <String>[];

  @override
  Future<void> report(final String tryonId) async {
    reported.add(tryonId);
    if (error case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('reports the try-on by its id', () async {
    final remote = _FakeRemote();

    final result = await TryonReportRepositoryImpl(
      remoteDataSource: remote,
    ).report('t1');

    expect(result.isSuccess, isTrue);
    expect(remote.reported, ['t1']);
  });

  test('a duplicate of an already-filed report counts as filed', () async {
    final result = await TryonReportRepositoryImpl(
      remoteDataSource: _FakeRemote(
        error: const PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      ),
    ).report('t1');

    expect(result.isSuccess, isTrue);
  });

  test('any other database error is a server failure', () async {
    final result = await TryonReportRepositoryImpl(
      remoteDataSource: _FakeRemote(
        error: const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      ),
    ).report('t1');

    expect(result.getError(), isA<ServerFailure>());
  });
}
