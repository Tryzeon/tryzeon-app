import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tryzeon/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements AuthRemoteDataSource {
  Object? signOutError;
  final List<String> calls = [];

  @override
  Future<void> signOut() async {
    calls.add('supabase');
    if (signOutError case final error?) throw error;
  }

  @override
  Future<void> signOutGoogle() async => calls.add('google');

  @override
  Future<void> signOutLine() async {
    calls.add('line');
    throw Exception('no LINE session');
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopLocal implements AuthLocalDataSource {
  Object? lastLoginTypeError;

  @override
  Future<UserType?> getLastLoginType() async {
    if (lastLoginTypeError case final error?) throw error;
    return null;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test(
    'signOut still succeeds and ends provider sessions when the Supabase server call fails',
    () async {
      final remote = _FakeRemote()
        ..signOutError = const SocketException('offline');
      final repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: _NoopLocal(),
      );

      final result = await repository.signOut();

      expect(result.isSuccess, isTrue);
      expect(remote.calls, ['supabase', 'google', 'line']);
    },
  );

  test('signOut succeeds when only a provider SDK fails', () async {
    final remote = _FakeRemote();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _NoopLocal(),
    );

    final result = await repository.signOut();

    expect(result.isSuccess, isTrue);
  });

  test(
    'a stored login type that no longer decodes reads as none chosen',
    () async {
      final repository = AuthRepositoryImpl(
        remoteDataSource: _FakeRemote(),
        localDataSource: _NoopLocal()
          ..lastLoginTypeError = const CacheDecodeException('admin'),
      );

      final result = await repository.getLastLoginType();

      expect(result.isSuccess, isTrue);
      expect(result.get(), isNull);
    },
  );
}
