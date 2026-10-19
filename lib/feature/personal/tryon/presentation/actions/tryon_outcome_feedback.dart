import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/common/usage_quota/presentation/usage_quota_format.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';

/// Called from the personal shell's build, not a tab page's, so a run started
/// from any tab is answered wherever the user is when it settles.
void listenToTryonOutcomes(final BuildContext context, final WidgetRef ref) {
  ref.listen(tryonControllerProvider, (final _, final outcome) {
    if (outcome == null || !context.mounted) return;
    switch (outcome) {
      case TryonSucceeded():
        HapticFeedback.heavyImpact();
      case TryonCancelled():
        break;
      case TryonAvatarMissing():
        TopNotification.show(context, message: '請先選擇試穿模特才能開始試穿呦！');
      case TryonQuotaExceeded(:final isVideo, :final quota):
        final tier =
            quota?.tier ??
            ref.read(appSubscriptionEntitlementProvider).value?.tier;
        _showQuotaExceeded(context, isVideo: isVideo, quota: quota, tier: tier);
      case TryonFailed(:final failure):
        TopNotification.show(context, message: failure.displayMessage());
    }
  });
}

void _showQuotaExceeded(
  final BuildContext context, {
  required final bool isVideo,
  required final UsageQuota? quota,
  required final AppSubscriptionTier? tier,
}) {
  final feature = isVideo ? '影片試穿' : '試穿';
  final exhausted = quota == null
      ? '$feature次數已用完'
      : exhaustedLabel(quota, feature: feature);

  if (tier == AppSubscriptionTier.max) {
    TopNotification.show(context, message: exhausted);
    return;
  }
  UpgradeDialog.show(
    context,
    title: '$feature次數已達上限',
    content: '$exhausted\n升級方案可以拿到更多次數！',
  );
}
