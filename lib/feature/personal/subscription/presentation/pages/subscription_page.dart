import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/mappers/subscription_plan_ui_mapper.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_provider.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  String _priceText(final SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.free => '\$0',
    SubscriptionPlan.pro => '\$299/月',
    SubscriptionPlan.max => '\$499/月',
  };

  /// Processes a subscription plan change.
  /// Checks limits and calls the backend with a placeholder for future payment integration.
  Future<void> _handleSubscriptionChange(
    final BuildContext context,
    final WidgetRef ref,
    final ValueNotifier<SubscriptionPlan?> processingPlan,
    final SubscriptionPlan currentPlan,
    final SubscriptionPlan targetPlan,
  ) async {
    // ★ Future payment integration placeholder:
    // e.g., final paymentToken = await ApplePay.presentPaymentSheet(...);
    // if (paymentToken == null) return; // User cancelled

    processingPlan.value = targetPlan;

    final useCase = ref.read(updateSubscriptionUseCaseProvider);
    final result = await useCase(targetPlan: targetPlan);

    if (!context.mounted) return;
    processingPlan.value = null;

    switch (result) {
      case Ok(value: final subscription):
        ref.invalidate(subscriptionProvider);
        TopNotification.show(
          context,
          message: '已成功變更至${subscription.plan.displayName}',
          type: NotificationType.success,
        );
      case Err(error: final failure):
        TopNotification.show(
          context,
          message: failure.message ?? '變更失敗，請稍後再試',
          type: NotificationType.error,
        );
    }
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final processingPlan = useState<SubscriptionPlan?>(
      null,
    ); // Tracks which plan is currently being processed

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('訂閱方案'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: subscriptionAsync.when(
          skipLoadingOnReload: true,
          skipError: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: (error as Failure).displayMessage(context),
            onRetry: () => ref.refresh(subscriptionProvider),
          ),
          data: (final subscription) {
            final currentPlan = subscription.plan;
            return SingleChildScrollView(
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
                        ref,
                        processingPlan,
                        plan: SubscriptionPlan.free,
                        description: '基本試穿功能',
                        features: ['每日 5 次試穿', '衣櫃容量 20 件'],
                        currentPlan: currentPlan,
                      ),
                      const SizedBox(height: 20),
                      _buildPlanCard(
                        context,
                        ref,
                        processingPlan,
                        plan: SubscriptionPlan.pro,
                        description: '進階試穿功能',
                        features: ['每日 20 次試穿', '衣櫃容量 50 件'],
                        currentPlan: currentPlan,
                      ),
                      const SizedBox(height: 20),
                      _buildPlanCard(
                        context,
                        ref,
                        processingPlan,
                        plan: SubscriptionPlan.max,
                        description: '專業試穿功能',
                        features: ['每日 50 次試穿', '衣櫃容量 200 件'],
                        currentPlan: currentPlan,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    final BuildContext context,
    final WidgetRef ref,
    final ValueNotifier<SubscriptionPlan?> processingPlan, {
    required final SubscriptionPlan plan,
    required final String description,
    required final List<String> features,
    required final SubscriptionPlan? currentPlan,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrent = currentPlan == plan;

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
                Text(plan.displayName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_priceText(plan), style: theme.textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
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
                if (currentPlan != null && !isCurrent)
                  _buildActionButton(
                    context,
                    isLoading: processingPlan.value == plan,
                    isDisabled: processingPlan.value != null,
                    onPressed: () => _handleSubscriptionChange(
                      context,
                      ref,
                      processingPlan,
                      currentPlan,
                      plan,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    final BuildContext context, {
    required final bool isLoading,
    required final bool isDisabled,
    required final VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('變更成此方案'),
      ),
    );
  }
}
