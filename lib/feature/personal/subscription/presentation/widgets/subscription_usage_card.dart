import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';

class SubscriptionUsageCard extends StatelessWidget {
  const SubscriptionUsageCard({
    required this.entitlement,
    required this.capabilities,
    required this.usage,
    required this.wardrobeCapacity,
    required this.onTap,
    required this.onUpgrade,
    super.key,
  });

  final AppSubscriptionEntitlement entitlement;
  final SubscriptionCapabilities? capabilities;
  final DailyUsage? usage;
  final WardrobeCapacity? wardrobeCapacity;
  final VoidCallback onTap;
  final VoidCallback onUpgrade;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    planName(entitlement.tier),
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '管理',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.primary,
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _QuotaStat(
                    label: '試穿剩餘',
                    value: formatRemaining(
                      used: usage?.tryonCount,
                      limit: capabilities?.dailyTryonLimit,
                    ),
                  ),
                  _QuotaStat(
                    label: '聊天剩餘',
                    value: formatRemaining(
                      used: usage?.chatCount,
                      limit: capabilities?.dailyChatLimit,
                    ),
                  ),
                  _QuotaStat(
                    label: '影片剩餘',
                    value: formatRemaining(
                      used: usage?.videoCount,
                      limit: capabilities?.dailyVideoLimit,
                    ),
                  ),
                  _QuotaStat(
                    label: '衣櫃空位',
                    value: formatRemaining(
                      used: wardrobeCapacity?.used,
                      limit: wardrobeCapacity?.limit,
                    ),
                  ),
                ],
              ),
              if (entitlement.isFree) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(onPressed: onUpgrade, child: const Text('升級方案')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors [SubscriptionUsageCard]'s layout so the real card swaps in without
/// a height jump; keep the two in sync.
class SubscriptionUsageCardSkeleton extends StatelessWidget {
  const SubscriptionUsageCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Skeletonizer(
      child: Card(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Plan', style: textTheme.headlineLarge),
                  const Spacer(),
                  Text('管理', style: textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'YYYY/MM/DD 續訂',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  _QuotaStat(label: '試穿剩餘', value: '00'),
                  _QuotaStat(label: '聊天剩餘', value: '00'),
                  _QuotaStat(label: '影片剩餘', value: '00'),
                  _QuotaStat(label: '衣櫃空位', value: '00'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotaStat extends StatelessWidget {
  const _QuotaStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
