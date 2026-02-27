import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/shells/store_shell.dart';
import 'package:tryzeon/feature/store/home/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/store/onboarding/presentation/pages/store_onboarding_page.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/pages/add_product_page.dart';
import 'package:tryzeon/feature/store/products/presentation/pages/product_detail_page.dart';
import 'package:tryzeon/feature/store/settings/presentation/pages/profile_setting_page.dart';
import 'package:tryzeon/feature/store/settings/presentation/pages/settings_page.dart';

final storeShellRoute = StatefulShellRoute.indexedStack(
  builder: (final context, final state, final navigationShell) =>
      StoreShell(navigationShell: navigationShell),
  branches: [
    // Branch 0: Home
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/store/home',
          builder: (final context, final state) => const StoreHomePage(),
        ),
      ],
    ),
  ],
);

// Full-screen routes (no shell)
final storeFullScreenRoutes = [
  GoRoute(
    path: '/store/onboarding',
    builder: (final context, final state) => const StoreOnboardingPage(),
  ),
  GoRoute(
    path: '/store/settings',
    builder: (final context, final state) => const StoreSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const StoreProfileSettingsPage(),
      ),
    ],
  ),
  GoRoute(
    path: '/store/products/add',
    builder: (final context, final state) => const AddProductPage(),
  ),
  GoRoute(
    path: '/store/products/:id',
    builder: (final context, final state) {
      final product = state.extra! as Product;
      return ProductDetailPage(product: product);
    },
  ),
];
