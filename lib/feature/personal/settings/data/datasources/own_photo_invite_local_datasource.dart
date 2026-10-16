import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class OwnPhotoInviteLocalDataSource {
  OwnPhotoInviteLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = AppConstants.keyOwnPhotoInviteDismissed;

  Future<bool> isDismissed() async => await _prefs.getBool(_key) ?? false;

  Future<void> dismiss() => _prefs.setBool(_key, true);

  Future<void> clear() => _prefs.remove(_key);
}
