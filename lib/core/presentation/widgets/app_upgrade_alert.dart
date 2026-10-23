import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';

/// Every store release is mandatory: the dialog has no Ignore or Later and
/// comes back on every launch, so an old build cannot be used once a newer
/// one is on the store.
Upgrader createAppUpgrader({
  final UpgraderOS? upgraderOS,
  final http.Client? client,
}) => Upgrader(
  durationUntilAlertAgain: Duration.zero,
  messages: _TraditionalChineseUpgraderMessages(),
  upgraderOS: upgraderOS,
  client: client,
);

/// upgrader's built-in `zh` messages are Simplified Chinese.
class _TraditionalChineseUpgraderMessages extends UpgraderMessages {
  _TraditionalChineseUpgraderMessages() : super(code: 'zh');

  @override
  String message(final UpgraderMessage messageKey) => switch (messageKey) {
    UpgraderMessage.title => '有新版本',
    UpgraderMessage.body =>
      '{{appName}} 已推出 {{currentAppStoreVersion}} 版，你目前使用的是 '
          '{{currentInstalledVersion}} 版。',
    UpgraderMessage.prompt => '請更新至最新版本以繼續使用。',
    UpgraderMessage.releaseNotes => '更新內容',
    UpgraderMessage.buttonTitleUpdate => '立即更新',
    UpgraderMessage.buttonTitleLater => '稍後',
    UpgraderMessage.buttonTitleIgnore => '忽略',
  };
}

class AppUpgradeAlert extends StatelessWidget {
  const AppUpgradeAlert({
    super.key,
    required this.upgrader,
    required this.navigatorKey,
    required this.child,
  });

  final Upgrader upgrader;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  @override
  Widget build(final BuildContext context) {
    return UpgradeAlert(
      dialogStyle: Theme.of(context).platform == TargetPlatform.iOS
          ? UpgradeDialogStyle.cupertino
          : UpgradeDialogStyle.material,
      upgrader: upgrader,
      navigatorKey: navigatorKey,
      showIgnore: false,
      showLater: false,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
