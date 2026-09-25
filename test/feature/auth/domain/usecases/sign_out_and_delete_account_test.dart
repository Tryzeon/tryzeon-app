import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/domain/services/image_file_cache.dart';
import 'package:tryzeon/core/domain/services/local_database.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/delete_account.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class _Journal {
  final List<String> steps = [];
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._journal);

  final _Journal _journal;
  Result<void, Failure> signOutResult = const Ok(null);
  Result<void, Failure> deleteAccountResult = const Ok(null);

  @override
  Future<Result<void, Failure>> signOut() async {
    _journal.steps.add('signOut');
    return signOutResult;
  }

  @override
  Future<Result<void, Failure>> deleteAccount() async {
    _journal.steps.add('deleteAccount');
    return deleteAccountResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeQueue implements AnalyticsEventQueue {
  _FakeQueue(this._journal);

  final _Journal _journal;
  bool failFlush = false;

  @override
  Future<void> forceFlush() async {
    _journal.steps.add('flush');
    if (failFlush) throw Exception('flush failed');
  }

  @override
  void enqueue(final AnalyticsEvent event) => throw UnimplementedError();

  @override
  void dispose() {}
}

class _FakeImageFileCache implements ImageFileCache {
  _FakeImageFileCache(this._journal);

  final _Journal _journal;

  @override
  Future<void> clear() async => _journal.steps.add('clearImageFileCache');

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeLocalDatabase implements LocalDatabase {
  _FakeLocalDatabase(this._journal);

  final _Journal _journal;

  @override
  Future<void> clear() async => _journal.steps.add('clearLocalDatabase');
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._journal);

  final _Journal _journal;

  @override
  Future<Result<void, Failure>> clearTryonPreferences() async {
    _journal.steps.add('clearPreferences');
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _Journal journal;
  late _FakeAuthRepository authRepository;
  late _FakeQueue queue;
  late SignOut signOut;

  setUp(() {
    journal = _Journal();
    authRepository = _FakeAuthRepository(journal);
    queue = _FakeQueue(journal);
    signOut = SignOut(
      authRepository: authRepository,
      analyticsQueue: queue,
      imageFileCache: _FakeImageFileCache(journal),
      localDatabase: _FakeLocalDatabase(journal),
      settingsRepository: _FakeSettingsRepository(journal),
    );
  });

  group('SignOut', () {
    test('runs every teardown step in order', () async {
      final result = await signOut();

      expect(result.isSuccess, isTrue);
      expect(journal.steps, [
        'flush',
        'signOut',
        'clearImageFileCache',
        'clearLocalDatabase',
        'clearPreferences',
      ]);
    });

    test('a failed flush does not stop the sign-out', () async {
      queue.failFlush = true;

      final result = await signOut();

      expect(result.isSuccess, isTrue);
      expect(journal.steps, contains('signOut'));
    });

    test('reports a failed Supabase sign-out after still clearing local data', () async {
      authRepository.signOutResult = const Err(NetworkFailure());

      final result = await signOut();

      expect(result.getError(), const NetworkFailure());
      expect(
        journal.steps,
        containsAll(['clearImageFileCache', 'clearLocalDatabase', 'clearPreferences']),
      );
    });
  });

  group('DeleteAccount', () {
    DeleteAccount build() => DeleteAccount(
      authRepository: authRepository,
      analyticsQueue: queue,
      signOut: signOut,
    );

    test('a failed server deletion returns the error and stays signed in', () async {
      authRepository.deleteAccountResult = const Err(ServerFailure());

      final result = await build()();

      expect(result.getError(), const ServerFailure());
      expect(journal.steps, ['flush', 'deleteAccount']);
    });

    test('a successful deletion signs out', () async {
      final result = await build()();

      expect(result.isSuccess, isTrue);
      expect(journal.steps.sublist(0, 3), ['flush', 'deleteAccount', 'flush']);
      expect(journal.steps, contains('signOut'));
    });
  });
}
