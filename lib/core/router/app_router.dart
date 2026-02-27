import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/router/auth_refresh_listenable.dart';
import 'package:tryzeon/core/router/routes/auth_routes.dart';
import 'package:tryzeon/core/router/routes/deep_link_routes.dart';
import 'package:tryzeon/core/router/routes/personal_routes.dart';
import 'package:tryzeon/core/router/routes/store_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'app_router.g.dart';

@riverpod
Raw<GoRouter> appRouter(final Ref ref) {
  final supabase = Supabase.instance.client;

  // Watch store profile for onboarding guard
  final storeProfileAsync = ref.watch(storeProfileProvider);

  final refreshListenable = AuthRefreshListenable(supabase.auth.onAuthStateChange);

  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: refreshListenable,
    redirect: (final context, final state) async {
      final session = supabase.auth.currentSession;
      final loggedIn = session != null;
      final path = state.matchedLocation;

      // 1. Auth Guard: not logged in → /auth/login
      if (!loggedIn && !path.startsWith('/auth')) {
        return '/auth/login';
      }

      // 2. Logged-in redirect: on auth pages → home
      if (loggedIn && path.startsWith('/auth')) {
        final getLoginType = ref.read(getLastLoginTypeUseCaseProvider);
        final result = await getLoginType();
        final userType = result.get();
        return userType == UserType.store ? '/store/home' : '/personal/home';
      }

      // 3. Onboarding Guard for store users
      if (loggedIn) {
        if (path.startsWith('/store') && !path.startsWith('/store/onboarding')) {
          final hasProfile = storeProfileAsync.asData?.value != null;
          if (!hasProfile && !storeProfileAsync.isLoading) {
            return '/store/onboarding';
          }
        }
      }

      return null; // no redirect
    },
    routes: [
      authRoutes,
      personalShellRoute,
      ...personalFullScreenRoutes,
      storeShellRoute,
      ...storeFullScreenRoutes,
      ...deepLinkRoutes,
    ],
  );
}
