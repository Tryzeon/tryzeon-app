import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class StoreTutorialLocalDataSource {
  StoreTutorialLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _key(final String storeId) =>
      '${AppConstants.keyStoreTutorialFinishedPrefix}$storeId';

  Future<bool> isFinished(final String storeId) async =>
      await _prefs.getBool(_key(storeId)) ?? false;

  Future<void> finish(final String storeId) =>
      _prefs.setBool(_key(storeId), true);
}
