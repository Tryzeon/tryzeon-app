import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/router/shells/personal_tab_navigator.dart';

class RecordingTabNavigator extends PersonalTabNavigator {
  final navigations = <PersonalTab>[];

  @override
  void goTo(final PersonalTab tab) => navigations.add(tab);
}
