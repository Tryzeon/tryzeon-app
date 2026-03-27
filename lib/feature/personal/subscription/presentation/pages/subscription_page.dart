import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/di/revenue_cat_providers.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/presentation/utils/revenue_cat_ui_utils.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final entitlementAsync = ref.watch(appSubscriptionEntitlementProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('訂閱方案'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: entitlementAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: error.displayMessage(context),
            onRetry: () => ref.refresh(appSubscriptionEntitlementProvider),
          ),
          data: (final entitlement) {
            final tier = entitlement.tier;
            final isPaidPlan = entitlement.hasActiveSubscription;
            final membershipTitle = switch (tier) {
              AppSubscriptionTier.max => '您目前是 Tryzeon Max 會員',
              AppSubscriptionTier.pro => '您目前是 Tryzeon Pro 會員',
              AppSubscriptionTier.free => '您目前是免費用戶',
            };
            final membershipDescription = switch (tier) {
              AppSubscriptionTier.max => '感謝您的支持，您目前已開通 Tryzeon 最高等級方案。',
              AppSubscriptionTier.pro => '感謝您的支持，您已解鎖 Tryzeon Pro 專屬功能。',
              AppSubscriptionTier.free =>
                '升級為 Tryzeon Pro 或 Tryzeon Max 會員即可解鎖更多試穿額度與專屬功能。',
            };
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPaidPlan ? Icons.star : Icons.star_border,
                    size: 64,
                    color: isPaidPlan
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    membershipTitle,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    membershipDescription,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (isPaidPlan)
                    FilledButton.icon(
                      onPressed: () =>
                          RevenueCatUiUtils.presentCustomerCenter(context, ref),
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('管理訂閱方案'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => RevenueCatUiUtils.presentPaywall(context),
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('查看升級方案'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
