import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/tryon_preferences_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';

void main() {
  late SharedPreferencesAsync prefs;
  late TryonPreferencesLocalDataSource dataSource;

  void seed(final Map<String, Object> data) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(data);
    prefs = SharedPreferencesAsync();
    dataSource = TryonPreferencesLocalDataSource(prefs);
  }

  setUp(() => seed({}));

  test('reads back what it wrote', () async {
    const preferences = TryonPreferences(
      scenePrompt: 'urban street',
      stylingPrompt: 'tucked in',
      transitionPrompt: 'jump cut',
      engine: TryonEngine.experimental,
    );

    await dataSource.write(preferences);

    expect(await dataSource.read(), preferences);
  });

  test('nothing stored reads as the defaults', () async {
    expect(await dataSource.read(), const TryonPreferences());
  });

  test('an unknown engine name falls back to the standard engine', () async {
    seed({AppConstants.keyTryonEngine: 'turbo'});

    expect((await dataSource.read()).engine, TryonEngine.standard);
  });

  test('an empty prompt removes its key instead of storing ""', () async {
    seed({
      AppConstants.keyTryonScenePrompt: 'urban street',
      AppConstants.keyTryonStylingPrompt: 'tucked in',
      AppConstants.keyTryonTransitionPrompt: 'jump cut',
    });

    await dataSource.write(const TryonPreferences(scenePrompt: ''));

    expect(await prefs.getKeys(), {AppConstants.keyTryonEngine});
  });

  test('clear removes only the try-on keys', () async {
    seed({
      AppConstants.keyTryonScenePrompt: 'urban street',
      AppConstants.keyTryonEngine: 'experimental',
      'unrelated': 'kept',
    });

    await dataSource.clear();

    expect(await prefs.getKeys(), {'unrelated'});
  });
}
