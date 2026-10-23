import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tryzeon/feature/store/tutorial/data/datasources/store_tutorial_local_datasource.dart';

void main() {
  late StoreTutorialLocalDataSource dataSource;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    dataSource = StoreTutorialLocalDataSource(SharedPreferencesAsync());
  });

  test('a store starts out not finished', () async {
    expect(await dataSource.isFinished('s1'), isFalse);
  });

  test('finishing is remembered', () async {
    await dataSource.finish('s1');

    expect(await dataSource.isFinished('s1'), isTrue);
  });

  test('finishing is remembered per store', () async {
    await dataSource.finish('s1');

    expect(await dataSource.isFinished('s2'), isFalse);
  });
}
