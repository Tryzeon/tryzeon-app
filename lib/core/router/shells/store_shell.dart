import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';

enum StoreTab {
  products(
    label: '商品',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    sfSymbol: 'bag',
  ),
  account(
    label: '我的',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    sfSymbol: 'person',
  );

  const StoreTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.sfSymbol,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String sfSymbol;
}

class StoreShell extends HookConsumerWidget {
  const StoreShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final lastTabTapTime = useState<DateTime?>(null);

    Future<void> switchToPersonal() async {
      await ref.read(setLastLoginTypeUseCaseProvider).call(UserType.personal);
      if (!context.mounted) return;
      context.go(AppRoutes.personalHome);
    }

    void onItemTapped(final int index) {
      const doubleTapThreshold = Duration(milliseconds: 400);
      final lastTabIndex = StoreTab.values.length - 1;

      if (index == lastTabIndex) {
        final now = DateTime.now();
        final last = lastTabTapTime.value;
        if (last != null && now.difference(last) < doubleTapThreshold) {
          lastTabTapTime.value = null;
          switchToPersonal();
          return;
        }
        lastTabTapTime.value = now;
      } else {
        // Reset so hopping away and back doesn't trigger a switch.
        lastTabTapTime.value = null;
      }

      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final mediaQuery = MediaQuery.of(context);
    // Own messenger so each page's Scaffold (not this shell's) hosts snackbars
    // and lifts them above its own FAB; AppSnackBar adds the nav-bar offset.
    final body = ScaffoldMessenger(
      child: MediaQuery(data: mediaQuery, child: navigationShell),
    );

    return MediaQuery(
      data: mediaQuery.copyWith(viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0)),
      child: PlatformInfo.isIOS26OrHigher()
          ? AdaptiveScaffold(
              minimizeBehavior: TabBarMinimizeBehavior.never,
              body: body,
              bottomNavigationBar: AdaptiveBottomNavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onTap: onItemTapped,
                useNativeBottomBar: true,
                items: StoreTab.values
                    .map(
                      (final tab) => AdaptiveNavigationDestination(
                        icon: tab.sfSymbol,
                        label: tab.label,
                      ),
                    )
                    .toList(),
              ),
            )
          : Scaffold(
              extendBody: true,
              body: body,
              bottomNavigationBar: AppBottomNavBar(
                selectedIndex: navigationShell.currentIndex,
                onTap: onItemTapped,
                items: StoreTab.values
                    .map(
                      (final tab) => AppBottomNavItem(
                        icon: tab.icon,
                        selectedIcon: tab.selectedIcon,
                        label: tab.label,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
