import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/routes/deep_link_routes.dart';

void main() {
  Future<Uri?> openDeepLink(
    final WidgetTester tester,
    final String link,
  ) async {
    Uri? landed;
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (final context, final state) => const SizedBox(),
        ),
        ...deepLinkRoutes,
        GoRoute(
          path: AppRoutes.personalShopProduct,
          builder: (final context, final state) {
            landed = state.uri;
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go(link);
    await tester.pumpAndSettle();
    return landed;
  }

  testWidgets('product deep link forwards the colour query', (
    final tester,
  ) async {
    final uri = await openDeepLink(tester, '/product/p1?color=c1');
    expect(uri.toString(), '/personal/shop/product/p1?color=c1');
  });

  testWidgets('product deep link without a colour has no query', (
    final tester,
  ) async {
    final uri = await openDeepLink(tester, '/product/p1');
    expect(uri.toString(), '/personal/shop/product/p1');
  });
}
