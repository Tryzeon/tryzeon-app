import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/common/settings/providers/settings_controller.dart';
import 'package:typed_result/typed_result.dart';

Future<void> confirmAndSignOut(final BuildContext context) async {
  final confirmed = await showAppOkCancelDialog(
    context: context,
    title: '登出',
    message: '你確定要登出嗎？',
    okLabel: '登出',
    cancelLabel: '取消',
    isDestructiveAction: true,
  );
  if (confirmed != OkCancelResult.ok || !context.mounted) return;

  final result = await _controller(context).signOut();
  if (!context.mounted) return;
  _reportFailure(context, result);
}

Future<void> confirmAndSwitchTo(final BuildContext context, final UserType target) async {
  final targetLabel = switch (target) {
    UserType.personal => '個人版',
    UserType.store => '店家版',
  };
  final confirmed = await showAppOkCancelDialog(
    context: context,
    title: '切換帳號',
    message: '你確定要切換到$targetLabel帳號嗎？',
    okLabel: '確定',
    cancelLabel: '取消',
  );
  if (confirmed != OkCancelResult.ok || !context.mounted) return;

  final result = await _controller(context).switchTo(target);
  if (!context.mounted) return;

  if (result.isFailure) {
    _reportFailure(context, result);
    return;
  }
  context.go(AppRoutes.homeForUserType(target));
}

Future<void> confirmAndDeleteAccount(final BuildContext context) async {
  final confirmed = await showAppOkCancelDialog(
    context: context,
    title: '刪除帳號',
    message: '此操作將永久刪除您的帳號及所有相關資料，包括個人資料、衣櫃、店家資料、商品等，且無法復原。您確定要繼續嗎？',
    okLabel: '刪除帳號',
    cancelLabel: '取消',
    isDestructiveAction: true,
  );
  if (confirmed != OkCancelResult.ok || !context.mounted) return;

  final result = await _controller(context).deleteAccount();
  if (!context.mounted) return;
  _reportFailure(context, result);
}

SettingsController _controller(final BuildContext context) => ProviderScope.containerOf(
  context,
  listen: false,
).read(settingsControllerProvider.notifier);

void _reportFailure(final BuildContext context, final Result<void, Failure> result) {
  if (result.isSuccess) return;
  TopNotification.show(context, message: result.getError()!.displayMessage(context));
}
