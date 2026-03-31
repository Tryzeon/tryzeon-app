import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/store_shell.dart';
import 'package:tryzeon/feature/store/home/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/store/onboarding/presentation/pages/store_onboarding_page.dart';
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
          path: AppRoutes.storeHome,
          builder: (final context, final state) => const StoreHomePage(),
        ),
      ],
    ),
  ],
);

// Full-screen routes (no shell)
final storeFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.storeOnboarding,
    builder: (final context, final state) => const StoreOnboardingPage(),
  ),
  GoRoute(
    path: AppRoutes.storeSettings,
    builder: (final context, final state) => const StoreSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const StoreProfileSettingsPage(),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.storeProductAdd,
    builder: (final context, final state) => const AddProductPage(),
  ),
  GoRoute(
    path: AppRoutes.storeProductDetail,
    builder: (final context, final state) {
      final productId = state.pathParameters['id']!;
      return ProductDetailPage(productId: productId);
    },
  ),
];
