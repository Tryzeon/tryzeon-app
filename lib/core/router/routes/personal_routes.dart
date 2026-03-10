import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/shells/personal_shell.dart';
import 'package:tryzeon/feature/personal/chat/presentation/pages/chat_page.dart';
import 'package:tryzeon/feature/personal/home/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/preferences_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/profile_setting_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/settings_page.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/product_detail_page.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/shop_page.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/store_page.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/pages/subscription_page.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/pages/wardrobe_page.dart';

final personalShellRoute = StatefulShellRoute.indexedStack(
  builder: (final context, final state, final navigationShell) =>
      PersonalShell(navigationShell: navigationShell),
  branches: [
    // Branch 0: Home
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/personal/home',
          builder: (final context, final state) => const HomePage(),
        ),
      ],
    ),
    // Branch 1: Shop
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/personal/shop',
          builder: (final context, final state) => const ShopPage(),
          routes: [
            GoRoute(
              path: 'product/:id',
              builder: (final context, final state) {
                final productId = state.pathParameters['id']!;
                return ProductDetailPage(productId: productId);
              },
            ),
            GoRoute(
              path: 'store/:storeId',
              builder: (final context, final state) {
                final storeId = state.pathParameters['storeId']!;
                return StorePage(storeId: storeId);
              },
            ),
          ],
        ),
      ],
    ),
    // Branch 2: Chat
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/personal/chat',
          builder: (final context, final state) => const ChatPage(),
        ),
      ],
    ),
    // Branch 3: Wardrobe
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/personal/wardrobe',
          builder: (final context, final state) => const PersonalPage(),
        ),
      ],
    ),
  ],
);

// Full-screen routes (no bottom nav)
final personalFullScreenRoutes = [
  GoRoute(
    path: '/personal/settings',
    builder: (final context, final state) => const PersonalSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const PersonalProfileSettingsPage(),
      ),
      GoRoute(
        path: 'preferences',
        builder: (final context, final state) => const PreferencesPage(),
      ),
      GoRoute(
        path: 'subscription',
        builder: (final context, final state) => const SubscriptionPage(),
      ),
    ],
  ),
];
