import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tryzeon/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:tryzeon/feature/auth/domain/usecases/delete_account.dart';
import 'package:tryzeon/feature/auth/domain/usecases/get_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/send_email_otp.dart';
import 'package:tryzeon/feature/auth/domain/usecases/set_last_login_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_in_with_provider.dart';
import 'package:tryzeon/feature/auth/domain/usecases/sign_out.dart';
import 'package:tryzeon/feature/auth/domain/usecases/verify_email_otp.dart';

part 'auth_providers.g.dart';

@riverpod
bool isAuthenticated(final Ref ref) {
  final client = Supabase.instance.client;
  // Listen to auth state changes and invalidate the provider to trigger rebuilds.
  final subscription = client.auth.onAuthStateChange.listen((final _) {
    ref.invalidateSelf();
  });
  ref.onDispose(subscription.cancel);

  return client.auth.currentSession != null;
}

// Data Source Providers
@riverpod
AuthRemoteDataSource authRemoteDataSource(final Ref ref) {
  return AuthRemoteDataSource(Supabase.instance.client);
}

@riverpod
AuthLocalDataSource authLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  return AuthLocalDataSource(isarService);
}

// Repository Provider
@riverpod
AuthRepository authRepository(final Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  final cacheService = ref.watch(cacheServiceProvider);
  final analyticsEventQueueService = ref.watch(analyticsEventQueueServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    cacheService: cacheService,
    analyticsEventQueueService: analyticsEventQueueService,
  );
}

// Use Case Providers
@riverpod
SignInWithProviderUseCase signInWithProviderUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithProviderUseCase(repository);
}

@riverpod
SendEmailOtpUseCase sendEmailOtpUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendEmailOtpUseCase(repository);
}

@riverpod
VerifyEmailOtpUseCase verifyEmailOtpUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyEmailOtpUseCase(repository);
}

@riverpod
SignOutUseCase signOutUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
}

@riverpod
GetLastLoginTypeUseCase getLastLoginTypeUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetLastLoginTypeUseCase(repository);
}

@riverpod
SetLastLoginTypeUseCase setLastLoginTypeUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SetLastLoginTypeUseCase(repository);
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(final Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return DeleteAccountUseCase(repository);
}
