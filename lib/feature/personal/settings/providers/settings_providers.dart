import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((final ref) {
  return SettingsRepositoryImpl();
});

final recommendNearbyShopsProvider =
    AsyncNotifierProvider<RecommendNearbyShopsNotifier, bool>(
      RecommendNearbyShopsNotifier.new,
    );

class RecommendNearbyShopsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final locationService = ref.read(locationServiceProvider);

    final isNearbyShopsRecommendationEnabled = await repository.getRecommendNearbyShops();

    // 如果設定開啟，但實際上系統權限已關閉，則同步回 false
    if (isNearbyShopsRecommendationEnabled) {
      final isLocationPermissionGranted = await locationService.hasPermission();
      if (!isLocationPermissionGranted) {
        await repository.setRecommendNearbyShops(false);
        return false;
      }
    }

    return isNearbyShopsRecommendationEnabled;
  }

  Future<void> toggle(final bool value) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setRecommendNearbyShops(value);
    state = AsyncData(value);
  }
}
