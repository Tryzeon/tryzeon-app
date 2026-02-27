import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/home/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';

class PersonalShell extends HookConsumerWidget {
  const PersonalShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final homePageController = useMemoized(HomePageController.new);

    useEffect(() {
      return homePageController.dispose;
    }, [homePageController]);

    Future<void> tryOnFromStorage(final String clothesPath) async {
      navigationShell.goBranch(0);
      if (homePageController.tryOnFromStorage != null) {
        await homePageController.tryOnFromStorage!(clothesPath);
      }
    }

    void onItemTapped(final int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final mediaQuery = MediaQuery.of(context);

    return PersonalEntryScope(
      tryOnFromStorage: tryOnFromStorage,
      child: MediaQuery(
        data: mediaQuery.copyWith(viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0)),
        child: AdaptiveScaffold(
          minimizeBehavior: TabBarMinimizeBehavior.never,
          body: MediaQuery(data: mediaQuery, child: navigationShell),
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onTap: onItemTapped,
            useNativeBottomBar: true,
            items: [
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS26OrHigher()
                    ? 'house'
                    : PlatformInfo.isIOS
                    ? CupertinoIcons.house
                    : Icons.home_outlined,
                label: '首頁',
              ),
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS26OrHigher()
                    ? 'cart'
                    : PlatformInfo.isIOS
                    ? CupertinoIcons.cart
                    : Icons.shopping_cart_outlined,
                label: '試衣間',
              ),
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS26OrHigher()
                    ? 'message'
                    : PlatformInfo.isIOS
                    ? CupertinoIcons.chat_bubble
                    : Icons.chat_outlined,
                label: '聊天',
              ),
              AdaptiveNavigationDestination(
                icon: PlatformInfo.isIOS26OrHigher()
                    ? 'person'
                    : PlatformInfo.isIOS
                    ? CupertinoIcons.person
                    : Icons.person_outline,
                label: '個人',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
