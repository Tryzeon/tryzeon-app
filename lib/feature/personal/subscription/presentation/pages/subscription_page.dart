import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/presentation/utils/revenue_cat_ui_utils.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/section_label.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/common/usage_quota/presentation/usage_quota_format.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entitlementAsync = ref.watch(appSubscriptionEntitlementProvider);
    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('訂閱方案')),
      body: SafeArea(
        top: false,
        child: _buildBody(ref, entitlementAsync, capabilitiesAsync),
      ),
    );
  }

  Widget _buildBody(
    final WidgetRef ref,
    final AsyncValue<AppSubscriptionEntitlement> entitlementAsync,
    final AsyncValue<SubscriptionCapabilities> capabilitiesAsync,
  ) {
    // Entitlement is structural (defines plan identity + CTA target). Without
    // it the page cannot render. Capabilities and usage degrade per-stat
    // inside the content. `value == null` keeps cached content during SWR.
    final entitlement = entitlementAsync.value;
    if (entitlement == null) {
      if (entitlementAsync.hasError) {
        return ErrorView(
          message: entitlementAsync.error!.displayMessage(),
          onRetry: () {
            ref.invalidate(appSubscriptionEntitlementProvider);
            ref.invalidate(subscriptionCapabilitiesProvider);
          },
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return _SubscriptionContent(
      entitlement: entitlement,
      capabilities: capabilitiesAsync.value,
    );
  }
}

class _SubscriptionContent extends ConsumerWidget {
  const _SubscriptionContent({required this.entitlement, this.capabilities});

  final AppSubscriptionEntitlement entitlement;
  final SubscriptionCapabilities? capabilities;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final tier = entitlement.tier;

    final wardrobeUsed = ref.watch(
      wardrobeItemsProvider.select((final v) => v.value?.length ?? 0),
    );
    final quota = ref.watch(usageQuotaProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('方案'),
          Card(
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        planName(tier),
                        style: textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (entitlement.hasActiveSubscription)
                        Chip(
                          label: Text(
                            '啟用中',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          backgroundColor: colorScheme.primaryContainer,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatRenewalLine(entitlement),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionLabel(_usageTitle(quota)),
          _BenefitRow(
            title: '試穿',
            trailingValue: formatUsage(
              used: quota?.tryonImage.used,
              limit: quota?.tryonImage.quota,
            ),
            isFirst: true,
          ),
          _BenefitRow(
            title: '影片',
            trailingValue: formatUsage(
              used: quota?.tryonVideo.used,
              limit: quota?.tryonVideo.quota,
            ),
          ),
          _BenefitRow(
            title: '衣櫃容量',
            trailingValue: formatUsage(
              used: wardrobeUsed,
              limit: capabilities?.wardrobeLimit,
            ),
          ),
          const SectionLabel('方案權益'),
          _BenefitRow(
            title: '影片試穿',
            trailingValue: formatBenefit(value: quota?.hasVideoAccess),
            isFirst: true,
          ),
          const _BenefitRow(title: '聊天', trailingValue: '不限次數＊'),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '＊適用合理使用政策',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PrimaryCta(tier: tier),
          if (tier == AppSubscriptionTier.pro) ...[
            const SizedBox(height: AppSpacing.sm),
            const _UpgradeToMaxCta(),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

String _usageTitle(final UsageQuota? quota) {
  if (quota == null) return '目前用量';
  final label = '${periodLabel(quota.period)}用量';
  final reset = resetLabel(quota);
  return reset == null ? label : '$label（$reset 重置）';
}

class _PrimaryCta extends ConsumerWidget {
  const _PrimaryCta({required this.tier});

  final AppSubscriptionTier tier;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isFree = tier == AppSubscriptionTier.free;
    final label = isFree ? '升級方案' : '管理方案';

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          if (isFree) {
            RevenueCatUiUtils.presentPaywall(context);
          } else {
            RevenueCatUiUtils.presentCustomerCenter(context);
          }
        },
        child: Text(label),
      ),
    );
  }
}

class _UpgradeToMaxCta extends StatelessWidget {
  const _UpgradeToMaxCta();

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => RevenueCatUiUtils.presentPaywall(context),
        child: const Text('升級至 Max'),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.title,
    required this.trailingValue,
    this.isFirst = false,
  });

  final String title;
  final String trailingValue;
  final bool isFirst;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hairline = BorderSide(
      color: colorScheme.outline,
      width: AppStroke.thin,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? hairline : BorderSide.none,
          bottom: hairline,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: textTheme.bodyLarge)),
          Text(
            trailingValue,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
