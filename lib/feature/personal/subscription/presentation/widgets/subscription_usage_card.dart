import 'package:flutter/material.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/utils/subscription_format.dart';

/// Account-page-only card showing current plan name + a single hero usage
/// stat (today's try-ons). Full per-feature usage breakdown lives on the
/// Subscription page (progressive disclosure — keeps Account page clean and
/// avoids ambient scarcity anxiety).
class SubscriptionUsageCard extends StatelessWidget {
  const SubscriptionUsageCard({
    required this.entitlement,
    required this.formattedRenewalLine,
    required this.dailyTryOnUsed,
    required this.dailyTryOnLimit,
    required this.onTap,
    super.key,
  });

  final AppSubscriptionEntitlement entitlement;
  final String? formattedRenewalLine;
  final int dailyTryOnUsed;
  final int dailyTryOnLimit;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    planName(entitlement.tier),
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (entitlement.hasActiveSubscription) _ActivePill(),
                ],
              ),
              if (formattedRenewalLine != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedRenewalLine!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _UsageStat(label: '今日試穿', used: dailyTryOnUsed, limit: dailyTryOnLimit),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.smMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '查看訂閱詳情',
                    style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        '啟用中',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  const _UsageStat({required this.label, required this.used, required this.limit});

  final String label;
  final int used;
  final int limit; // -1 → unlimited; 0 → not available for this tier

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isUnlimited = limit < 0;
    final isLocked = limit == 0;
    final progress = isUnlimited || isLocked ? 0.0 : (used / limit).clamp(0.0, 1.0);

    final Widget valueText;
    if (isLocked) {
      valueText = Text(
        '未開通',
        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    } else {
      final limitText = isUnlimited ? '∞' : limit.toString();
      valueText = RichText(
        text: TextSpan(
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
          children: [
            TextSpan(text: '$used'),
            TextSpan(
              text: ' / $limitText',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valueText,
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
