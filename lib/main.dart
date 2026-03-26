import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/router/app_router.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'firebase_options.dart';

Duration? customRetry(final int retryCount, final Object error) {
  if (retryCount >= 3) return null;

  if (error is NetworkFailure) {
    return Duration(milliseconds: 200 * (1 << retryCount));
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (final FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  // RevenueCat SDK initialization
  if (kDebugMode) {
    await Purchases.setLogLevel(LogLevel.debug);
  }

  final purchasesConfig = PurchasesConfiguration(Env.revenueCatApiKey);
  await Purchases.configure(purchasesConfig);

  // Log user identity – RevenueCat will use an anonymous ID until login
  // After user logs in (Supabase auth), call Purchases.logIn(userId) to link
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    await Purchases.logIn(currentUser.id);
  }

  runApp(const ProviderScope(retry: customRetry, child: Tryzeon()));
}

class Tryzeon extends HookConsumerWidget {
  const Tryzeon({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Analytics Lifecycle Observer
    useOnAppLifecycleStateChange((final previous, final current) {
      if (current == AppLifecycleState.paused || current == AppLifecycleState.detached) {
        ref.read(analyticsEventQueueServiceProvider).forceFlush();
      }
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TryZeon',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
