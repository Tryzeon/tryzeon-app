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

/// Matches deep link paths like `/store/<uuid>`.
final _storeDeepLinkPattern = RegExp(
  '^/store/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

@riverpod
Raw<GoRouter> appRouter(final Ref ref) {
  final supabase = Supabase.instance.client;
  final refreshListenable = AuthRefreshListenable(supabase.auth.onAuthStateChange);

  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: refreshListenable,
    redirect: (final context, final state) async {
      final isLoggedIn = supabase.auth.currentSession != null;
      final path = state.matchedLocation;
      final isAuthPath = path.startsWith('/auth');

      // 1. 未登入 → 導向登入頁
      if (!isLoggedIn) return isAuthPath ? null : '/auth/login';

      // 2. 已登入但仍處於登入頁 → 導向首頁
      if (isAuthPath) return _resolveHomePath(ref);

      // 3. 商家 Onboarding 攔截 (排除 Deep Link 與 Onboarding 頁面本身)
      //    使用 ref.read 取得最新的 store profile 狀態
      final storeProfileAsync = ref.read(storeProfileProvider);
      if (_needsStoreOnboarding(path, storeProfileAsync)) {
        return '/store/onboarding';
      }

      return null;
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

  // 監聽 store profile 變化，觸發 redirect 重新評估，
  // 而不是重建整個 GoRouter（避免覆蓋 deep link 導航）。
  ref.listen(storeProfileProvider, (final _, final __) {
    refreshListenable.refresh();
  });

  return router;
}

/// 根據上次登入類型決定首頁路徑。
Future<String> _resolveHomePath(final Ref ref) async {
  final getLoginType = ref.read(getLastLoginTypeUseCaseProvider);
  final result = await getLoginType();
  final userType = result.get();
  return userType == UserType.store ? '/store/home' : '/personal/home';
}

/// 判斷目前商家路徑是否需要被 Onboarding 攔截。
bool _needsStoreOnboarding(
  final String path,
  final AsyncValue<dynamic> storeProfileAsync,
) {
  if (!path.startsWith('/store')) return false;
  if (path.startsWith('/store/onboarding')) return false;
  if (_storeDeepLinkPattern.hasMatch(path)) return false;

  final hasProfile = storeProfileAsync.asData?.value != null;
  return !hasProfile && !storeProfileAsync.isLoading;
}
