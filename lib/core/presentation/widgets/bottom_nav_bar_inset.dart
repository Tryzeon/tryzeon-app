import 'package:flutter/widgets.dart';

/// Height the tab shell's floating nav bar covers above the safe area, for
/// widgets that must clear it but live in a Scaffold that doesn't know about
/// it. Absent (0) on full-screen routes.
class BottomNavBarInset extends InheritedWidget {
  const BottomNavBarInset({required this.overlap, required super.child, super.key});

  final double overlap;

  static double of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BottomNavBarInset>()?.overlap ?? 0;

  @override
  bool updateShouldNotify(final BottomNavBarInset oldWidget) =>
      overlap != oldWidget.overlap;
}
