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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Future<void> handleRecommendNearbyShopsToggle(
      final bool isNearbyShopsRecommendationEnabled,
    ) async {
      if (isNearbyShopsRecommendationEnabled) {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.requestPermission();

        if (!context.mounted) return;

        if (permission == LocationPermission.denied) {
          TopNotification.show(context, message: '需要開啟定位權限才能使用此功能');
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
      appBar: AppBar(title: const Text('偏好設定')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '管理你的個人偏好。',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ToggleRow(
                title: '推薦附近店家',
                subtitle: '根據你的位置推薦附近的優質店家',
                value: recommendNearbyShopsAsync.value ?? false,
                isLoading: recommendNearbyShopsAsync.isLoading,
                onChanged: recommendNearbyShopsAsync.isLoading
                    ? null
                    : handleRecommendNearbyShopsToggle,
                isFirst: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
    this.isFirst = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;
  final bool isFirst;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hairline = BorderSide(color: colorScheme.outline, width: AppStroke.thin);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: isFirst ? hairline : BorderSide.none, bottom: hairline),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (isLoading)
            SizedBox(
              width: AppSpacing.mdLg,
              height: AppSpacing.mdLg,
              child: CircularProgressIndicator(
                strokeWidth: AppStroke.regular,
                color: colorScheme.primary,
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: colorScheme.primary,
              activeThumbColor: colorScheme.onPrimary,
            ),
        ],
      ),
    );
  }
}
