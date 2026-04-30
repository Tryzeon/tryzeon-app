import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';

class PreferencesPage extends HookConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final recommendNearbyShopsAsync = ref.watch(recommendNearbyShopsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleRecommendNearbyShopsToggle(
      final bool isNearbyShopsRecommendationEnabled,
    ) async {
      if (isNearbyShopsRecommendationEnabled) {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.requestPermission();

        if (!context.mounted) return;

        if (permission == LocationPermission.denied) {
          TopNotification.show(
            context,
            message: '需要開啟定位權限才能使用此功能',
            type: NotificationType.warning,
          );
          return;
        }

        if (permission == LocationPermission.deniedForever) {
          await showDialog(
            context: context,
            builder: (final context) => AlertDialog.adaptive(
              title: const Text('需要定位權限'),
              content: const Text('為了推薦附近的店家，我們需要您的位置權限。請前往設定開啟權限。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Geolocator.openAppSettings();
                  },
                  child: const Text('前往設定'),
                ),
              ],
            ),
          );
          return;
        }
      }
      ref
          .read(recommendNearbyShopsProvider.notifier)
          .toggle(isNearbyShopsRecommendationEnabled);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('偏好設定', style: textTheme.headlineMedium),
                        Text('管理您的個人偏好', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildSectionCard(
                    context: context,
                    title: '探索',
                    children: [
                      recommendNearbyShopsAsync.when(
                        data: (final value) => SwitchListTile.adaptive(
                          value: value,
                          onChanged: handleRecommendNearbyShopsToggle,
                          title: Text('推薦附近店家', style: textTheme.titleSmall),
                          subtitle: Text('根據您的位置推薦附近的優質店家', style: textTheme.bodyMedium),
                          contentPadding: EdgeInsets.zero,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator.adaptive()),
                        error: (final err, final stack) => Text('發生錯誤: $err'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required final BuildContext context,
    required final String title,
    required final List<Widget> children,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
