import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_plan_info.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription_plans.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/update_subscription.dart';
import 'package:typed_result/typed_result.dart';

part 'subscription_provider.g.dart';

// DataSource Providers
@riverpod
SubscriptionRemoteDataSource subscriptionRemoteDataSource(final Ref ref) {
  return SubscriptionRemoteDataSource(Supabase.instance.client);
}

@riverpod
SubscriptionLocalDataSource subscriptionLocalDataSource(final Ref ref) {
  return SubscriptionLocalDataSource(ref.watch(isarServiceProvider));
}

// Repository Provider
@riverpod
SubscriptionRepository subscriptionRepository(final Ref ref) {
  return SubscriptionRepositoryImpl(
    remoteDataSource: ref.watch(subscriptionRemoteDataSourceProvider),
    localDataSource: ref.watch(subscriptionLocalDataSourceProvider),
  );
}

// Use Case Providers
@riverpod
GetSubscription getSubscriptionUseCase(final Ref ref) {
  return GetSubscription(
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}

@riverpod
UpdateSubscription updateSubscriptionUseCase(final Ref ref) {
  return UpdateSubscription(
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}

@riverpod
GetSubscriptionPlans getSubscriptionPlansUseCase(final Ref ref) {
  return GetSubscriptionPlans(
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}

// Data Providers
@riverpod
Future<Subscription> subscription(final Ref ref) async {
  final getSubscriptionUseCase = ref.watch(getSubscriptionUseCaseProvider);
  final result = await getSubscriptionUseCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

@riverpod
Future<List<SubscriptionPlanInfo>> subscriptionPlans(final Ref ref) async {
  final useCase = ref.watch(getSubscriptionPlansUseCaseProvider);
  final result = await useCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}
