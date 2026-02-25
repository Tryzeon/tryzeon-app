import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:typed_result/typed_result.dart';

Duration? customRetry(final int retryCount, final Object error) {
  if (retryCount >= 3) return null;

  if (error is NetworkFailure) {
    return Duration(milliseconds: 200 * (1 << retryCount));
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    final isLoading = useState(true);
    final userType = useState<UserType?>(null);

    useEffect(() {
      Future<void> checkAuthStatus() async {
        final getLoginTypeUseCase = ref.read(getLastLoginTypeUseCaseProvider);
        final result = await getLoginTypeUseCase();
        switch (result) {
          case Ok(:final value):
            userType.value = value;
          case Err():
            userType.value = null;
        }
        isLoading.value = false;
      }

      checkAuthStatus();
      return null;
    }, []);

    return MaterialApp(
      title: 'TryZeon',
      theme: AppTheme.lightTheme,
      home: isLoading.value
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : userType.value == null
          ? const LoginPage()
          : userType.value == UserType.store
          ? const StoreEntry()
          : const PersonalEntry(),
    );
  }
}
