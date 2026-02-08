import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_repository.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription.dart';
import 'package:typed_result/typed_result.dart';

part 'subscription_provider.g.dart';

// DataSource Provider
@riverpod
SubscriptionRemoteDataSource subscriptionRemoteDataSource(final Ref ref) {
  return SubscriptionRemoteDataSource(Supabase.instance.client);
}

// Repository Provider
@riverpod
SubscriptionRepository subscriptionRepository(final Ref ref) {
  return SubscriptionRepositoryImpl(ref.watch(subscriptionRemoteDataSourceProvider));
}

// Use Case Provider
@riverpod
GetSubscription getSubscriptionUseCase(final Ref ref) {
  return GetSubscription(
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}

// Subscription Data Provider
@riverpod
Future<Subscription> subscription(final Ref ref) async {
  final getSubscriptionUseCase = ref.watch(getSubscriptionUseCaseProvider);
  final result = await getSubscriptionUseCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}
