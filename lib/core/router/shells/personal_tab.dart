import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'personal_tab.g.dart';

/// The personal shell's bottom-nav tabs, in branch order.
enum PersonalTab {
  home(
    label: '首頁',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    sfSymbol: 'house',
  ),
  shop(
    label: '試衣間',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    sfSymbol: 'cart',
  ),
  chat(
    label: '聊天',
    icon: Icons.chat_outlined,
    selectedIcon: Icons.chat,
    sfSymbol: 'message',
  ),
  wardrobe(
    label: '衣櫃',
    icon: Icons.checkroom_outlined,
    selectedIcon: Icons.checkroom,
    sfSymbol: 'hanger',
  ),
  account(
    label: '我的',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    sfSymbol: 'person',
  );

  const PersonalTab({
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

/// A tap on the already-selected tab. [sequence] makes each tap a distinct state
/// value, so repeated taps on the same tab still notify listeners.
typedef PersonalTabReselect = ({PersonalTab tab, int sequence});

/// The shell emits, pages listen — e.g. to scroll back to top on re-tap.
@Riverpod(keepAlive: true)
class PersonalTabReselectSignal extends _$PersonalTabReselectSignal {
  @override
  PersonalTabReselect? build() => null;

  void emit(final PersonalTab tab) =>
      state = (tab: tab, sequence: (state?.sequence ?? 0) + 1);
}
