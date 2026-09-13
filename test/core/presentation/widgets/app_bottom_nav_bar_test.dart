import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

final _theme = AppTheme.lightTheme;

const _items = [
  AppBottomNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首頁'),
  AppBottomNavItem(icon: Icons.chat_outlined, selectedIcon: Icons.chat, label: '聊天'),
  AppBottomNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: '我的'),
];

const _fiveItems = [
  ..._items,
  AppBottomNavItem(
    icon: Icons.checkroom_outlined,
    selectedIcon: Icons.checkroom,
    label: '衣櫃',
  ),
  AppBottomNavItem(
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    label: '試衣間',
  ),
];

Widget _subject({
  required final int selectedIndex,
  final ValueChanged<int>? onTap,
  final double safeAreaBottom = 0,
  final List<AppBottomNavItem> items = _items,
}) {
  return MaterialApp(
    theme: _theme,
    home: MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(bottom: safeAreaBottom)),
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: AppBottomNavBar(
          items: items,
          selectedIndex: selectedIndex,
          onTap: onTap ?? (_) {},
        ),
      ),
    ),
  );
}

Finder _pillOf(final String label) => find.ancestor(
  of: find.text(label),
  matching: find.byKey(AppBottomNavBar.selectedPillKey),
);

void main() {
  testWidgets('renders every item label', (final tester) async {
    await tester.pumpWidget(_subject(selectedIndex: 0));

    for (final item in _items) {
      expect(find.text(item.label), findsOneWidget);
    }
  });

  testWidgets('tapping an item reports its index', (final tester) async {
    int? tapped;
    await tester.pumpWidget(_subject(selectedIndex: 0, onTap: (final i) => tapped = i));

    await tester.tap(find.text('聊天'));

    expect(tapped, 1);
  });

  testWidgets('only the selected item is marked selected in semantics', (
    final tester,
  ) async {
    await tester.pumpWidget(_subject(selectedIndex: 2));

    expect(
      tester.getSemantics(find.text('我的')),
      matchesSemantics(
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: '我的',
      ),
    );
    expect(
      tester.getSemantics(find.text('首頁')),
      matchesSemantics(
        isSelected: false,
        hasSelectedState: true,
        isButton: true,
        hasTapAction: true,
        label: '首頁',
      ),
    );
  });

  testWidgets('selected item shows its filled icon, others their outlined icon', (
    final tester,
  ) async {
    await tester.pumpWidget(_subject(selectedIndex: 1));

    expect(find.byIcon(Icons.chat), findsOneWidget);
    expect(find.byIcon(Icons.chat_outlined), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
  });

  testWidgets('selected item uses primary colour, others use onSurfaceVariant', (
    final tester,
  ) async {
    await tester.pumpWidget(_subject(selectedIndex: 0));

    final colorScheme = _theme.colorScheme;
    Color? iconColor(final IconData icon) => tester.widget<Icon>(find.byIcon(icon)).color;

    expect(iconColor(Icons.home), colorScheme.primary);
    expect(iconColor(Icons.chat_outlined), colorScheme.onSurfaceVariant);
  });

  testWidgets('only the selected item sits on a pill', (final tester) async {
    await tester.pumpWidget(_subject(selectedIndex: 1));

    expect(_pillOf('聊天'), findsOneWidget);
    expect(_pillOf('首頁'), findsNothing);
    expect(_pillOf('我的'), findsNothing);
  });

  testWidgets('selection changes without animating', (final tester) async {
    await tester.pumpWidget(_subject(selectedIndex: 0));
    await tester.pumpWidget(_subject(selectedIndex: 1));

    expect(_pillOf('聊天'), findsOneWidget);
    expect(find.byIcon(Icons.chat), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('capsule shrinks to its items and is centred', (final tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_subject(selectedIndex: 0));

    final screen = tester.getSize(find.byType(MaterialApp));
    final capsule = tester.getRect(find.byKey(AppBottomNavBar.capsuleKey));

    expect(
      capsule.width,
      3 * AppSpacing.bottomNavBarItemWidth + 2 * (AppSpacing.sm + AppStroke.thin),
    );
    expect(capsule.center.dx, screen.width / 2);
    expect(capsule.height, AppSpacing.bottomNavBarHeight);
    expect(capsule.bottom, screen.height - AppSpacing.bottomNavBarBottomMargin);
  });

  testWidgets('capsule never exceeds the screen minus its side margins', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_subject(selectedIndex: 0, items: _fiveItems));

    final screen = tester.getSize(find.byType(MaterialApp));
    final capsule = tester.getRect(find.byKey(AppBottomNavBar.capsuleKey));

    expect(capsule.left, AppSpacing.bottomNavBarHorizontalMargin);
    expect(capsule.right, screen.width - AppSpacing.bottomNavBarHorizontalMargin);
    for (final item in _fiveItems) {
      expect(find.text(item.label), findsOneWidget);
    }
  });

  testWidgets('occupies exactly the body overlap plus the safe-area inset', (
    final tester,
  ) async {
    await tester.pumpWidget(_subject(selectedIndex: 0, safeAreaBottom: 34));

    final bar = tester.getRect(find.byType(AppBottomNavBar));
    final capsule = tester.getRect(find.byKey(AppBottomNavBar.capsuleKey));
    final screen = tester.getSize(find.byType(MaterialApp));

    expect(bar.height, AppSpacing.bottomNavBarOverlap + 34);
    expect(capsule.bottom, screen.height - 34 - AppSpacing.bottomNavBarBottomMargin);
  });
}
