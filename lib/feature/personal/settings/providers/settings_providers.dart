import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(final Ref ref) {
  return SettingsRepositoryImpl();
}

@riverpod
class RecommendNearbyShops extends _$RecommendNearbyShops {
  @override
  Future<bool> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final locationService = ref.read(locationServiceProvider);

    final isNearbyShopsRecommendationEnabledResult = await repository
        .getRecommendNearbyShops();
    if (isNearbyShopsRecommendationEnabledResult.isFailure) {
      // Default to false on error, or you might want to throw/log
      return false;
    }
    final isNearbyShopsRecommendationEnabled = isNearbyShopsRecommendationEnabledResult
        .get()!;

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
    final result = await repository.setRecommendNearbyShops(value);
    if (result.isSuccess) {
      state = AsyncData(value);
    } else {
      // Optionally set state to error or just revert
      // For now, we update state only on success
    }
  }
}

@riverpod
class VideoPromptConfigNotifier extends _$VideoPromptConfigNotifier {
  @override
  Future<VideoPromptConfig> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.getVideoPromptConfig();
    return result.isSuccess ? result.get()! : const VideoPromptConfig();
  }

  Future<bool> save(final VideoPromptConfig config) async {
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.setVideoPromptConfig(config);
    if (result.isSuccess) {
      state = AsyncData(config);
      return true;
    }
    return false;
  }
}
