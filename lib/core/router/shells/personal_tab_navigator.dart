import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';

part 'personal_tab_navigator.g.dart';

/// Switches personal tabs from outside the shell's widget tree, through the key
/// the personal shell route is built with.
class PersonalTabNavigator {
  final shellKey = GlobalKey<StatefulNavigationShellState>();

  void goTo(final PersonalTab tab) {
    final shell = shellKey.currentState;
    if (shell == null) {
      throw StateError('Cannot go to $tab: the personal shell is not mounted');
    }
    shell.goBranch(tab.index);
  }
}

@Riverpod(keepAlive: true)
PersonalTabNavigator personalTabNavigator(final Ref ref) =>
    PersonalTabNavigator();
