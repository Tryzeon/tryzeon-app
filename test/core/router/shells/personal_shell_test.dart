import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/personal_shell.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../support/wardrobe_test_doubles.dart';

const _dock = Key('outfit-dock');

GoRoute _page(final String path, {final List<RouteBase> routes = const []}) => GoRoute(
  path: path,
  builder: (final _, final state) => Scaffold(body: Text(state.matchedLocation)),
  routes: routes,
);

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems([wardrobeItem('a')])),
      ],
    );
    addTearDown(container.dispose);

    router = GoRouter(
      initialLocation: AppRoutes.personalHome,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (final _, final _, final navigationShell) =>
              PersonalShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [_page(AppRoutes.personalHome)]),
            StatefulShellBranch(
              routes: [
                _page(AppRoutes.personalShop, routes: [_page('product/:id')]),
              ],
            ),
            StatefulShellBranch(routes: [_page(AppRoutes.personalChat)]),
            StatefulShellBranch(
              routes: [
                _page(AppRoutes.personalWardrobe, routes: [_page('item/:id')]),
              ],
            ),
            StatefulShellBranch(routes: [_page(AppRoutes.personalAccount)]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pumpShell(final WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    ),
  );

  testWidgets('dock shows on a product page pushed from the home tab', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();

    router.push(AppRoutes.personalShopProductPath('p1'));
    await tester.pumpAndSettle();

    expect(find.text('/personal/shop/product/p1'), findsOneWidget);
    expect(find.byKey(_dock), findsOneWidget);
  });

  testWidgets('dock shows on a wardrobe item page pushed from the chat tab', (
    final tester,
  ) async {
    await pumpShell(tester);
    router.go(AppRoutes.personalChat);
    await tester.pumpAndSettle();
    container.read(outfitTrayProvider.notifier).open();

    router.push(AppRoutes.personalWardrobeItemPath('a'));
    await tester.pumpAndSettle();

    expect(find.byKey(_dock), findsOneWidget);
  });

  testWidgets('dock hides again once the pushed garment page is popped', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();
    router.push(AppRoutes.personalShopProductPath('p1'));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.personalHome), findsOneWidget);
    expect(find.byKey(_dock), findsNothing);
  });

  testWidgets('dock stays hidden on the home tab while the tray is open', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();
    await tester.pumpAndSettle();

    expect(find.byKey(_dock), findsNothing);
  });
}
