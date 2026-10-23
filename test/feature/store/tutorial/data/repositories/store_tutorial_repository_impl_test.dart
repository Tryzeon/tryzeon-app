import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tryzeon/feature/store/tutorial/data/datasources/store_tutorial_local_datasource.dart';
import 'package:tryzeon/feature/store/tutorial/data/repositories/store_tutorial_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

class _BrokenDataSource extends StoreTutorialLocalDataSource {
  _BrokenDataSource(super.prefs);

  @override
  Future<bool> isFinished(final String storeId) =>
      Future.error(StateError('broken'));
}

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  test('finishing is read back', () async {
    final repository = StoreTutorialRepositoryImpl(
      StoreTutorialLocalDataSource(prefs),
    );

    await repository.finish('s1');

    expect((await repository.isFinished('s1')).get(), isTrue);
  });

  test('an unreadable flag is a failure', () async {
    final repository = StoreTutorialRepositoryImpl(_BrokenDataSource(prefs));

    expect((await repository.isFinished('s1')).isFailure, isTrue);
  });
}
