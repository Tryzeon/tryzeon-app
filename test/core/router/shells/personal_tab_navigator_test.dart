import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/router/shells/personal_tab_navigator.dart';

GoRoute _page(final String path) => GoRoute(
  path: path,
  builder: (final _, final state) => Text(state.matchedLocation),
);

void main() {
  late PersonalTabNavigator navigator;
  late GoRouter router;

  setUp(() {
    navigator = PersonalTabNavigator();
    router = GoRouter(
      initialLocation: AppRoutes.personalHome,
      routes: [
        StatefulShellRoute.indexedStack(
          key: navigator.shellKey,
          builder: (final _, final _, final navigationShell) => navigationShell,
          branches: [
            for (final path in [
              AppRoutes.personalHome,
              AppRoutes.personalShop,
              AppRoutes.personalChat,
              AppRoutes.personalWardrobe,
              AppRoutes.personalAccount,
            ])
              StatefulShellBranch(routes: [_page(path)]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  testWidgets('goTo switches the shell to that tab', (final tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    navigator.goTo(PersonalTab.shop);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.personalShop,
    );
  });

  test('goTo throws while no shell is mounted', () {
    expect(() => navigator.goTo(PersonalTab.shop), throwsStateError);
  });
}
