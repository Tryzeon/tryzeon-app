import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/own_photo_invite_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/data/datasources/tryon_preferences_local_datasource.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:typed_result/typed_result.dart';

void main() {
  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    repository = SettingsRepositoryImpl(
      TryonPreferencesLocalDataSource(prefs),
      OwnPhotoInviteLocalDataSource(prefs),
    );
  });

  test('dismissing the own-photo invite is remembered', () async {
    expect((await repository.isOwnPhotoInviteDismissed()).get(), isFalse);

    await repository.dismissOwnPhotoInvite();

    expect((await repository.isOwnPhotoInviteDismissed()).get(), isTrue);
  });

  test(
    'clearing device preferences resets try-on preferences and the invite',
    () async {
      await repository.setTryonPreferences(
        const TryonPreferences(scenePrompt: 'urban street'),
      );
      await repository.dismissOwnPhotoInvite();

      final result = await repository.clearDevicePreferences();

      expect(result.isSuccess, isTrue);
      expect(
        (await repository.getTryonPreferences()).get(),
        const TryonPreferences(),
      );
      expect((await repository.isOwnPhotoInviteDismissed()).get(), isFalse);
    },
  );
}
