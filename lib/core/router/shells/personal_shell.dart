import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/home/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/main/personal_entry_scope.dart';

class PersonalTabDestination {
  const PersonalTabDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const personalTabDestinations = [
  PersonalTabDestination(label: '首頁', icon: Icons.home_outlined),
  PersonalTabDestination(label: '試衣間', icon: Icons.shopping_cart_outlined),
  PersonalTabDestination(label: '聊天', icon: Icons.chat_outlined),
  PersonalTabDestination(label: '衣櫃', icon: Icons.checkroom_outlined),
  PersonalTabDestination(label: '我的', icon: Icons.person_outline),
];

class PersonalShell extends HookConsumerWidget {
  const PersonalShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final homePageController = useMemoized(HomePageController.new);

    useEffect(() {
      return homePageController.dispose;
    }, [homePageController]);

    Future<void> tryOnFromStorage(
      final List<String> clothesPaths, {
      final TryOnMode mode = TryOnMode.image,
    }) async {
      navigationShell.goBranch(0);
      if (homePageController.tryOnFromStorage != null) {
        await homePageController.tryOnFromStorage!(clothesPaths, mode: mode);
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
      homePageController: homePageController,
      child: MediaQuery(
        data: mediaQuery.copyWith(viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0)),
        child: AdaptiveScaffold(
          minimizeBehavior: TabBarMinimizeBehavior.never,
          body: MediaQuery(data: mediaQuery, child: navigationShell),
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onTap: onItemTapped,
            useNativeBottomBar: true,
            items: personalTabDestinations
                .map(
                  (final destination) => AdaptiveNavigationDestination(
                    icon: _adaptiveIcon(destination),
                    label: destination.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

Object _adaptiveIcon(final PersonalTabDestination destination) {
  if (PlatformInfo.isIOS26OrHigher()) {
    return switch (destination.label) {
      '首頁' => 'house',
      '試衣間' => 'cart',
      '聊天' => 'message',
      '衣櫃' => 'hanger',
      '我的' => 'person',
      _ => 'circle',
    };
  }

  if (PlatformInfo.isIOS) {
    return switch (destination.label) {
      '首頁' => CupertinoIcons.house,
      '試衣間' => CupertinoIcons.cart,
      '聊天' => CupertinoIcons.chat_bubble,
      '衣櫃' => CupertinoIcons.collections,
      '我的' => CupertinoIcons.person,
      _ => CupertinoIcons.circle,
    };
  }

  return destination.icon;
}
