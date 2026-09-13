import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/bottom_nav_bar_inset.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

const _items = [
  AppBottomNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首頁'),
  AppBottomNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: '我的'),
];

const _fabKey = ValueKey('fab');

Widget _page({required final bool withFab}) => Scaffold(
  floatingActionButton: withFab
      ? Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.bottomNavBarOverlap),
          child: FloatingActionButton(
            key: _fabKey,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        )
      : null,
  body: Builder(
    builder: (final context) => TextButton(
      onPressed: () => AppSnackBar.show(context, message: 'saved'),
      child: const Text('show'),
    ),
  ),
);

Widget _shell({required final bool withFab}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    extendBody: true,
    bottomNavigationBar: AppBottomNavBar(items: _items, selectedIndex: 0, onTap: (_) {}),
    body: ScaffoldMessenger(
      child: BottomNavBarInset(
        overlap: AppSpacing.bottomNavBarOverlap,
        child: _page(withFab: withFab),
      ),
    ),
  ),
);

Widget _fullScreen() =>
    MaterialApp(theme: AppTheme.lightTheme, home: _page(withFab: false));

Future<Rect> _showSnackBar(final WidgetTester tester) async {
  await tester.tap(find.text('show'));
  await tester.pumpAndSettle();
  return tester.getRect(
    find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first,
  );
}

void main() {
  testWidgets('floats a fixed gap above the capsule when the page has no FAB', (
    final tester,
  ) async {
    await tester.pumpWidget(_shell(withFab: false));
    final snackBar = await _showSnackBar(tester);
    final capsule = tester.getRect(find.byKey(AppBottomNavBar.capsuleKey));

    expect(snackBar.bottom, capsule.top - AppSpacing.sm);
  });

  testWidgets('floats above the page FAB instead of overlapping it', (
    final tester,
  ) async {
    await tester.pumpWidget(_shell(withFab: true));
    final snackBar = await _showSnackBar(tester);
    final fab = tester.getRect(find.byKey(_fabKey));

    expect(snackBar.bottom, lessThanOrEqualTo(fab.top));
  });

  testWidgets('sits a fixed gap above the safe area on a full-screen route', (
    final tester,
  ) async {
    await tester.pumpWidget(_fullScreen());
    final snackBar = await _showSnackBar(tester);
    final screen = tester.getSize(find.byType(MaterialApp));

    expect(snackBar.bottom, screen.height - AppSpacing.sm);
  });
}
