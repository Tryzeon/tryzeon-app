// lib/feature/personal/account/presentation/pages/account_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/di/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/nav_row.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/shared/measurements/utils/measurements_completion.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/presentation/providers/personal_settings_controller.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/widgets/subscription_usage_card.dart';
import 'package:tryzeon/feature/personal/usage/presentation/providers/daily_usage_providers.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(personalSettingsControllerProvider);

    ref.listen(personalSettingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(
          context,
          message: next.error.displayMessage(context),
          type: NotificationType.error,
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: const Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppSpacing.md),
                      _ProfileHeader(),
                      SizedBox(height: AppSpacing.lg),
                      Divider(),
                      _SectionLabel('訂閱方案'),
                      _SubscriptionSection(),
                      _SectionLabel('身形'),
                      _BodyMeasurementsRow(),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MY ACCOUNT',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('我的帳戶', style: textTheme.headlineMedium),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '設定',
                onPressed: () => context.push(AppRoutes.personalSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends HookConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profileAsync = ref.watch(userProfileProvider);
    final avatarFileAsync = ref.watch(avatarFileProvider);
    final user = ref.watch(currentUserProvider);

    final profile = profileAsync.value;
    final avatarFile = avatarFileAsync.value;
    final email = user?.email ?? user?.userMetadata?['email'] as String?;

    final isProfileLoading = profileAsync.isLoading && !profileAsync.hasValue;
    final hasProfileError = profileAsync.hasError;
    final isAvatarLoading = avatarFileAsync.isLoading && !avatarFileAsync.hasValue;

    Widget buildAvatar() {
      if (isProfileLoading || isAvatarLoading) {
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      if (hasProfileError || profile == null) {
        return Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant);
      }
      if (avatarFile != null) {
        return Image.file(avatarFile, fit: BoxFit.cover);
      }
      return Icon(Icons.person, color: colorScheme.onSurfaceVariant);
    }

    Widget buildInfo() {
      if (isProfileLoading) {
        return Text(
          '載入中…',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
      if (hasProfileError) {
        return Text('載入個人資料失敗', style: theme.textTheme.titleMedium);
      }
      if (profile == null) {
        return Text('尚未建立個人資料', style: theme.textTheme.titleMedium);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(profile.name, style: theme.textTheme.titleMedium),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(child: buildAvatar()),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(child: buildInfo()),
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.personalSettingsProfile),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('編輯', style: theme.textTheme.labelSmall),
        ),
      ],
    );
  }
}

class _SubscriptionSection extends HookConsumerWidget {
  const _SubscriptionSection();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entitlementAsync = ref.watch(appSubscriptionEntitlementProvider);
    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final usageAsync = ref.watch(dailyUsageTodayProvider);

    void openSubscription() => context.push(AppRoutes.personalSubscription);
    // Entitlement is structural (defines plan identity); without it the card
    // has no meaning. Capabilities and usage degrade per-stat inside the card.
    final entitlement = entitlementAsync.value;
    if (entitlement == null) {
      return entitlementAsync.hasError
          ? _SubscriptionErrorCard(onTap: openSubscription)
          : const _SubscriptionSkeletonCard();
    }

    return SubscriptionUsageCard(
      entitlement: entitlement,
      formattedRenewalLine: formatRenewalLine(entitlement),
      dailyTryOnUsed: usageAsync.value?.tryonCount,
      dailyTryOnLimit: capabilitiesAsync.value?.dailyTryOnLimit,
      onTap: openSubscription,
    );
  }
}

/// Layout-only skeleton matching [SubscriptionUsageCard]'s structure so the
/// real card swaps in without a height jump. Skeletonizer shimmers over the
/// placeholder text — the strings themselves are arbitrary.
class _SubscriptionSkeletonCard extends StatelessWidget {
  const _SubscriptionSkeletonCard();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Skeletonizer(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan', style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Renewing on YYYY-MM-DD',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('0 / 00', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '今日試穿',
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(height: 2, color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.smMd),
            Center(
              child: Text(
                '查看訂閱詳情',
                style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionErrorCard extends StatelessWidget {
  const _SubscriptionErrorCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            '很抱歉，無法載入訂閱資訊，請稍後再試！',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyMeasurementsRow extends HookConsumerWidget {
  const _BodyMeasurementsRow();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    final String? trailing;
    if (profileAsync.isLoading && !profileAsync.hasValue) {
      trailing = null;
    } else {
      final filled = countFilledMeasurements(profileAsync.value?.measurements);
      if (filled == 0) {
        trailing = '未填寫';
      } else if (filled == totalMeasurementFields) {
        trailing = '已完成';
      } else {
        trailing = '$filled / $totalMeasurementFields 已填寫';
      }
    }

    return NavRow(
      icon: Icons.straighten_outlined,
      title: '身形資料',
      trailingValue: trailing,
      isFirst: true,
      onTap: () => context.push(AppRoutes.personalSettingsBodyMeasurements),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
