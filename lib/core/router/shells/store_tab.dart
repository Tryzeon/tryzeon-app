import 'package:flutter/material.dart';

/// The store shell's bottom-nav tabs, in branch order.
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
