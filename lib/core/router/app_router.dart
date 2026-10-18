import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/auth_refresh_listenable.dart';
import 'package:tryzeon/core/router/routes/auth_routes.dart';
import 'package:tryzeon/core/router/routes/deep_link_routes.dart';
import 'package:tryzeon/core/router/routes/personal_routes.dart';
import 'package:tryzeon/core/router/routes/store_routes.dart';
import 'package:tryzeon/core/router/shells/personal_tab_navigator.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/main.dart';
import 'package:typed_result/typed_result.dart';

part 'app_router.g.dart';

@riverpod
Raw<GoRouter> appRouter(final Ref ref) {
  final authIdentity = ref.read(authIdentityServiceProvider);
  final refreshListenable = AuthRefreshListenable(authIdentity.watchUserId());

  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    observers: [
      FirebaseAnalyticsObserver(analytics: ref.read(firebaseAnalyticsProvider)),
    ],
    redirect: (final context, final state) {
      final isLoggedIn = authIdentity.currentUserId != null;
      final path = state.matchedLocation;
      final isAuthPath = path == AppRoutes.login;

      // 1. Signed out → go to the login page
      if (!isLoggedIn) {
        return isAuthPath ? null : AppRoutes.login;
      }

      // 2. Signed in but still on the login page → go home
      if (isAuthPath) return _resolveHomePath(ref);

      // 3. Store onboarding gate (deep links and the onboarding pages
      //    themselves are excluded)
      final storeRedirect = _handleStoreOnboardingRedirect(
        path,
        _storeOnboardingGate(ref.read(storeProfileProvider)),
      );
      if (storeRedirect != null) return storeRedirect;

      // 4. Personal onboarding gate (deep-link content pages are exempted
      //    inside, so they take priority)
      final personalRedirect = _handlePersonalOnboardingRedirect(
        path,
        _personalOnboardingGate(ref.read(userProfileProvider)),
      );
      if (personalRedirect != null) return personalRedirect;

      return null;
    },
    routes: [
      authRoutes,
      personalShellRoute(ref.read(personalTabNavigatorProvider).shellKey),
      ...personalFullScreenRoutes,
      storeShellRoute,
      ...storeFullScreenRoutes,
      ...deepLinkRoutes,
    ],
  );

  // Re-run redirect instead of rebuilding the whole GoRouter (which would
  // clobber deep-link navigation), and only when a gate's input changes: a
  // refresh re-parses the route stack into new pushed matches, so a pop made in
  // the same frame (a settings page closing after its save) is lost and the
  // page reappears.
  ref.listen(storeProfileProvider.select(_storeOnboardingGate), (
    final _,
    final _,
  ) {
    refreshListenable.refresh();
  });

  ref.listen(userProfileProvider.select(_personalOnboardingGate), (
    final _,
    final _,
  ) {
    refreshListenable.refresh();
  });

  return router;
}

Future<String> _resolveHomePath(final Ref ref) async {
  final getLoginType = ref.read(getLastLoginTypeUseCaseProvider);
  final result = await getLoginType();
  final userType = result.get();
  return AppRoutes.homeForUserType(userType ?? UserType.personal);
}

typedef _OnboardingGate = ({bool settled, bool passed});

_OnboardingGate _storeOnboardingGate(
  final AsyncValue<StoreProfile?> storeProfileAsync,
) => (
  settled: !storeProfileAsync.isLoading && !storeProfileAsync.hasError,
  passed: storeProfileAsync.asData?.value != null,
);

_OnboardingGate _personalOnboardingGate(
  final AsyncValue<UserProfile?> userProfileAsync,
) => (
  settled: !userProfileAsync.isLoading && !userProfileAsync.hasError,
  passed: userProfileAsync.asData?.value?.isOnboarded ?? false,
);

String? _handleStoreOnboardingRedirect(
  final String path,
  final _OnboardingGate gate,
) {
  if (!path.startsWith(AppRoutes.dashboardRoot)) return null;
  if (!gate.settled) return null;

  if (path == AppRoutes.dashboardOnboarding) {
    return gate.passed ? AppRoutes.dashboardAccount : null;
  }

  return gate.passed ? null : AppRoutes.dashboardOnboarding;
}

String? _handlePersonalOnboardingRedirect(
  final String path,
  final _OnboardingGate gate,
) {
  if (!path.startsWith(AppRoutes.personalRoot)) return null;

  if (path.startsWith(AppRoutes.personalShopProductPrefix) ||
      path.startsWith(AppRoutes.personalShopStorePrefix)) {
    return null;
  }

  if (!gate.settled) return null;

  if (path == AppRoutes.personalOnboarding) {
    return gate.passed ? AppRoutes.personalHome : null;
  }

  return gate.passed ? null : AppRoutes.personalOnboarding;
}
