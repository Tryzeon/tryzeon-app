import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/subscription/presentation/providers/subscription_provider.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final currentPlan = subscriptionAsync.whenOrNull(
      data: (final subscription) => subscription.plan,
      error: (final error, final stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            TopNotification.show(
              context,
              message: '很抱歉，無法載入您的訂閱資訊，請稍後再試',
              type: NotificationType.error,
            );
          }
        });
        return null;
      },
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('訂閱方案'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '解鎖完整功能',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '選擇最適合您的方案',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  _buildPlanCard(
                    context,
                    title: SubscriptionPlan.free.displayName,
                    price: '\$0',
                    description: '基本試穿功能',
                    features: ['每日 5 次試穿', '衣櫃容量 20 件'],
                    isCurrent: currentPlan == SubscriptionPlan.free,
                  ),
                  const SizedBox(height: 20),
                  _buildPlanCard(
                    context,
                    title: SubscriptionPlan.pro.displayName,
                    price: '\$12.99/月',
                    description: '進階試穿功能',
                    features: ['每日 20 次試穿', '衣櫃容量 50 件'],
                    isCurrent: currentPlan == SubscriptionPlan.pro,
                  ),
                  const SizedBox(height: 20),
                  _buildPlanCard(
                    context,
                    title: SubscriptionPlan.max.displayName,
                    price: '\$29.99/月',
                    description: '專業試穿功能',
                    features: ['每日 50 次試穿', '衣櫃容量 200 件'],
                    isCurrent: currentPlan == SubscriptionPlan.max,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    final BuildContext context, {
    required final String title,
    required final String price,
    required final String description,
    required final List<String> features,
    required final bool isCurrent,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = isCurrent ? colorScheme.primary : colorScheme.outlineVariant;
    final borderWidth = isCurrent ? 2.0 : 1.0;
    final backgroundColor = colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        children: [
          if (isCurrent)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  '目前方案',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...features.map(
                  (final feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: isCurrent ? colorScheme.primary : colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          feature,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
