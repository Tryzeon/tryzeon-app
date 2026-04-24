import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

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
      child: child ?? const SizedBox.shrink(),
    );
  }
}
