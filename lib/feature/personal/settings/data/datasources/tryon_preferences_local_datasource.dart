import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';

class TryonPreferencesLocalDataSource {
  TryonPreferencesLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _keys = {
    AppConstants.keyTryonScenePrompt,
    AppConstants.keyTryonStylingPrompt,
    AppConstants.keyTryonTransitionPrompt,
    AppConstants.keyTryonEngine,
  };

  Future<TryonPreferences> read() async {
    final values = await _prefs.getAll(allowList: _keys);
    return TryonPreferences(
      scenePrompt: values[AppConstants.keyTryonScenePrompt] as String?,
      stylingPrompt: values[AppConstants.keyTryonStylingPrompt] as String?,
      transitionPrompt:
          values[AppConstants.keyTryonTransitionPrompt] as String?,
      engine:
          TryonEngine.values.asNameMap()[values[AppConstants.keyTryonEngine]] ??
          TryonEngine.standard,
    );
  }

  Future<void> write(final TryonPreferences preferences) async {
    await _writePrompt(
      AppConstants.keyTryonScenePrompt,
      preferences.scenePrompt,
    );
    await _writePrompt(
      AppConstants.keyTryonStylingPrompt,
      preferences.stylingPrompt,
    );
    await _writePrompt(
      AppConstants.keyTryonTransitionPrompt,
      preferences.transitionPrompt,
    );
    await _prefs.setString(
      AppConstants.keyTryonEngine,
      preferences.engine.name,
    );
  }

  Future<void> clear() => _prefs.clear(allowList: _keys);

  Future<void> _writePrompt(final String key, final String? value) async {
    if (value != null && value.isNotEmpty) {
      await _prefs.setString(key, value);
    } else {
      await _prefs.remove(key);
    }
  }
}
