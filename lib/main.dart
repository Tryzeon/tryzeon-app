import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

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
