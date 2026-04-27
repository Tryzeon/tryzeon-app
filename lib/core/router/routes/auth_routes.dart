import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/auth/presentation/pages/unified_login_page.dart';

final authRoutes = GoRoute(
  path: AppRoutes.login,
  builder: (final context, final state) => const UnifiedLoginPage(),
);
