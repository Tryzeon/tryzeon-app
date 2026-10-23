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
  upgraderOS: upgraderOS,
  client: client,
);

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
