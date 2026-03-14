import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_plan_info.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_provider.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  String _priceText(final SubscriptionPlanInfo planInfo) {
    if (planInfo.price == 0) return '\$0';
    return '\$${planInfo.price}/月';
  }

  List<String> _features(final SubscriptionPlanInfo planInfo) {
    return [
      '衣櫃容量 ${planInfo.wardrobeLimit} 件',
      '每日 ${planInfo.tryonLimit} 次照片試穿',
      '每日 ${planInfo.videoLimit} 次影片試穿',
    ];
  }

  Future<void> _handleSubscriptionChange(
    final BuildContext context,
    final WidgetRef ref,
    final ValueNotifier<String?> processingPlanId,
    final SubscriptionPlanInfo targetPlanInfo,
  ) async {
    processingPlanId.value = targetPlanInfo.id;

    final useCase = ref.read(updateSubscriptionUseCaseProvider);
    final result = await useCase(targetPlan: targetPlanInfo.id);

    if (!context.mounted) return;
    processingPlanId.value = null;

    switch (result) {
      case Ok():
        ref.invalidate(subscriptionProvider);
        TopNotification.show(
          context,
          message: '已成功變更至${targetPlanInfo.name}',
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
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final processingPlanId = useState<String?>(null);

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
            onRetry: () {
              ref.invalidate(subscriptionProvider);
              ref.invalidate(subscriptionPlansProvider);
            },
          ),
          data: (final subscription) {
            final currentPlanId = subscription.plan;
            return plansAsync.when(
              skipLoadingOnReload: true,
              skipError: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (final error, final stack) => ErrorView(
                message: (error as Failure).displayMessage(context),
                onRetry: () => ref.refresh(subscriptionPlansProvider),
              ),
              data: (final plans) {
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
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ...plans.map(
                        (final planInfo) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildPlanCard(
                            context,
                            ref,
                            processingPlanId,
                            planInfo: planInfo,
                            currentPlanId: currentPlanId,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    final BuildContext context,
    final WidgetRef ref,
    final ValueNotifier<String?> processingPlanId, {
    required final SubscriptionPlanInfo planInfo,
    required final String currentPlanId,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrent = currentPlanId == planInfo.id;

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
                Text(planInfo.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_priceText(planInfo), style: theme.textTheme.displayLarge),
                const SizedBox(height: 24),
                ..._features(planInfo).map(
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
                if (!isCurrent)
                  _buildActionButton(
                    isLoading: processingPlanId.value == planInfo.id,
                    isDisabled: processingPlanId.value != null,
                    onPressed: () => _handleSubscriptionChange(
                      context,
                      ref,
                      processingPlanId,
                      planInfo,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
