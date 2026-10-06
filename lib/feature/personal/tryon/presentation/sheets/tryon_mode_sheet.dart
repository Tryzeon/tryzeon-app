import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_settings_view.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_mode_icon.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';

class TryonModeSheet extends HookConsumerWidget {
  const TryonModeSheet({super.key, required this.onModeSelected});

  final ValueChanged<TryonMode> onModeSelected;

  static Future<void> show({
    required final BuildContext context,
    required final ValueChanged<TryonMode> onModeSelected,
  }) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => TryonModeSheet(onModeSelected: onModeSelected),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final preferences = ref.watch(tryonPreferencesProvider).value;
    final isSettingsOpen = useState(false);

    return AnimatedSize(
      duration: AppDuration.standard,
      curve: AppCurves.standard,
      alignment: Alignment.topCenter,
      child: isSettingsOpen.value && preferences != null
          ? TryonSettingsView(
              initial: preferences,
              onBack: () => isSettingsOpen.value = false,
            )
          : _ModePickerView(
              preferences: preferences,
              onModeSelected: onModeSelected,
              onOpenSettings: preferences == null
                  ? null
                  : () => isSettingsOpen.value = true,
            ),
    );
  }
}

enum _ModeAvailability { open, locked, exhausted }

typedef _ModeQuota = ({_ModeAvailability availability, int? remaining});

_ModeQuota _quotaOf({required final int? limit, required final int? used}) {
  if (limit == 0) {
    return (availability: _ModeAvailability.locked, remaining: null);
  }
  if (limit == null || used == null) {
    return (availability: _ModeAvailability.open, remaining: null);
  }
  final remaining = math.max(0, limit - used);
  return (
    availability: remaining == 0
        ? _ModeAvailability.exhausted
        : _ModeAvailability.open,
    remaining: remaining,
  );
}

class _ModePickerView extends ConsumerWidget {
  const _ModePickerView({
    required this.preferences,
    required this.onModeSelected,
    required this.onOpenSettings,
  });

  final TryonPreferences? preferences;
  final ValueChanged<TryonMode> onModeSelected;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final capabilities = ref.watch(subscriptionCapabilitiesProvider).value;
    final usage = ref.watch(dailyUsageTodayProvider).value;
    final canUpgrade = ref.watch(
      appSubscriptionEntitlementProvider.select(
        (final async) => switch (async.value?.tier) {
          null || AppSubscriptionTier.max => false,
          _ => true,
        },
      ),
    );
    final preferences = this.preferences;
    final onOpenSettings = this.onOpenSettings;

    // Fail open: the server enforces entitlement and quota on submit, so an
    // unknown limit must never block a mode the user may have paid for.
    final imageQuota = _quotaOf(
      limit: capabilities?.dailyTryonLimit,
      used: usage?.tryonCount,
    );
    final videoQuota = _quotaOf(
      limit: capabilities?.dailyVideoLimit,
      used: usage?.videoCount,
    );

    void select(final TryonMode mode) {
      Navigator.of(context).pop();
      onModeSelected(mode);
    }

    void upgrade() {
      Navigator.of(context).pop();
      context.push(AppRoutes.personalSubscription);
    }

    return AppSheet(
      title: '選擇試穿方式',
      // Lives in the title row rather than on a tile so it can never be
      // mistaken for the tile's "start generating" tap target.
      trailing: IconButton(
        icon: const Icon(Icons.tune_rounded),
        tooltip: '試穿設定',
        onPressed: onOpenSettings,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (preferences != null && onOpenSettings != null)
              _SettingsSummary(preferences: preferences, onTap: onOpenSettings),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ModeTile(
                      mode: TryonMode.image,
                      title: '圖片試穿',
                      subtitle: '換上這件的定裝照',
                      quota: imageQuota,
                      unlockLabel: '升級方案解鎖',
                      canUpgrade: canUpgrade,
                      onSelect: () => select(TryonMode.image),
                      onUpgrade: upgrade,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: _ModeTile(
                      mode: TryonMode.video,
                      title: '影片試穿',
                      subtitle: '穿著展示的影片',
                      detail: preferences != null && preferences.hasTransition
                          ? '轉場：${preferences.transitionPrompt}'
                          : null,
                      quota: videoQuota,
                      unlockLabel: '升級至 Max 方案解鎖',
                      canUpgrade: canUpgrade,
                      onSelect: () => select(TryonMode.video),
                      onUpgrade: upgrade,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spells out what the next generation will apply, which a dot on the
/// settings button could only hint at. Transition is video-only, so it lives
/// on the video tile instead.
class _SettingsSummary extends StatelessWidget {
  const _SettingsSummary({required this.preferences, required this.onTap});

  final TryonPreferences preferences;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final parts = [
      if (preferences.hasStyling) '穿搭：${preferences.stylingPrompt}',
      if (preferences.hasScene) '場景：${preferences.scenePrompt}',
      if (preferences.hasCustomEngine) '實驗模型',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(
          parts.join('、'),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: AppSpacing.md,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    this.detail,
    required this.quota,
    required this.unlockLabel,
    required this.canUpgrade,
    required this.onSelect,
    required this.onUpgrade,
  });

  static const ColorFilter _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  final TryonMode mode;
  final String title;
  final String subtitle;
  final String? detail;
  final _ModeQuota quota;
  final String unlockLabel;
  final bool canUpgrade;
  final VoidCallback onSelect;
  final VoidCallback onUpgrade;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = this.detail;
    final remaining = quota.remaining;
    final availability = quota.availability;
    final isOpen = availability == _ModeAvailability.open;

    final upgradeLabel = switch (availability) {
      _ModeAvailability.open => null,
      _ModeAvailability.locked => unlockLabel,
      _ModeAvailability.exhausted => canUpgrade ? '升級方案取得更多次數' : null,
    };
    final statusLine = switch (availability) {
      _ModeAvailability.open when remaining != null => '今日剩 $remaining 次',
      _ModeAvailability.open || _ModeAvailability.locked => subtitle,
      _ModeAvailability.exhausted when canUpgrade => '今日次數已用完',
      _ModeAvailability.exhausted => '今日次數已用完，明天再來試試',
    };
    final onTap = isOpen ? onSelect : (upgradeLabel != null ? onUpgrade : null);
    final mutedStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    Widget icon = TryonModeIcon(mode: mode);
    if (!isOpen) {
      icon = Opacity(
        opacity: AppOpacity.overlay,
        child: ColorFiltered(colorFilter: _greyscale, child: icon),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const Spacer(),
                  if (availability == _ModeAvailability.locked)
                    Icon(
                      Icons.lock_rounded,
                      size: AppSpacing.md,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(statusLine, style: mutedStyle),
              if (detail != null && isOpen) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail,
                  style: mutedStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (upgradeLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  upgradeLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
