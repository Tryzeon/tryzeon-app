import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tab_reselect.g.dart';

/// A tap on the already-selected tab while its branch shows the tab's root
/// page. [sequence] makes each tap a distinct state value, so repeated taps on
/// the same tab still notify listeners.
typedef TabReselect = ({Enum tab, int sequence});

/// The shell emits, pages listen — e.g. to scroll back to top on re-tap.
@Riverpod(keepAlive: true)
class TabReselectSignal extends _$TabReselectSignal {
  @override
  TabReselect? build() => null;

  void emit(final Enum tab) =>
      state = (tab: tab, sequence: (state?.sequence ?? 0) + 1);
}

extension TabSelection on StatefulNavigationShell {
  /// Follows the iOS tab bar: re-tapping the selected tab pops its branch back
  /// to the root page, and only a re-tap on the root page is announced through
  /// [signal]. [tab]'s index is its branch index.
  void selectTab(final Enum tab, final TabReselectSignal signal) {
    if (tab.index != currentIndex) {
      goBranch(tab.index);
      return;
    }
    final branchNavigator = shellRouteContext.navigatorKey.currentState;
    if (branchNavigator != null && branchNavigator.canPop()) {
      goBranch(tab.index, initialLocation: true);
      return;
    }
    signal.emit(tab);
  }
}
