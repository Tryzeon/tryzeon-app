import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StoreShell extends StatelessWidget {
  const StoreShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context) {
    return navigationShell;
  }
}
