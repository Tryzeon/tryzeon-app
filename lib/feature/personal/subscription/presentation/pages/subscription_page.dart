import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/di/revenue_cat_providers.dart';
import 'package:tryzeon/core/modules/revenue_cat/presentation/utils/revenue_cat_ui_utils.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isProAsync = ref.watch(isProActiveProvider);
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
        child: isProAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: (error as Failure).displayMessage(context),
            onRetry: () => ref.refresh(isProActiveProvider),
          ),
          data: (final isPro) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPro ? Icons.star : Icons.star_border,
                    size: 64,
                    color: isPro ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPro ? '您目前是 Tryzeon Pro 會員' : '您目前是免費用戶',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPro ? '感謝您的支持，您已解鎖所有完整功能！' : '升級為 Tryzeon Pro 會員即可解鎖更多試穿額度與專屬功能。',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (isPro)
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
