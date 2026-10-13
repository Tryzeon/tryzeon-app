import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
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
      case TryonRateLimited(:final isVideo):
        UpgradeDialog.show(
          context,
          title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
          content: isVideo
              ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
              : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
        );
      case TryonFailed(:final failure):
        TopNotification.show(context, message: failure.displayMessage());
    }
  });
}
