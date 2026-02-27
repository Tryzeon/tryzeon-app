import 'package:go_router/go_router.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/pages/email_login_page.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/auth/presentation/pages/personal_login_page.dart';
import 'package:tryzeon/feature/auth/presentation/pages/store_login_page.dart';

final authRoutes = GoRoute(
  path: '/auth/login',
  builder: (final context, final state) => const LoginPage(),
  routes: [
    GoRoute(
      path: 'personal',
      builder: (final context, final state) => const PersonalLoginPage(),
    ),
    GoRoute(
      path: 'store',
      builder: (final context, final state) => const StoreLoginPage(),
    ),
    GoRoute(
      path: 'email',
      builder: (final context, final state) {
        final userType = state.extra as UserType? ?? UserType.personal;
        return EmailLoginPage(userType: userType);
      },
    ),
  ],
);
