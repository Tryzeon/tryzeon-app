import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/subscription/domain/repositories/subscription_repository.dart';
import 'package:tryzeon/feature/subscription/domain/usecases/get_subscription.dart';
import 'package:typed_result/typed_result.dart';

// DataSource Provider
final subscriptionRemoteDataSourceProvider = Provider<SubscriptionRemoteDataSource>((
  final ref,
) {
  return SubscriptionRemoteDataSource(Supabase.instance.client);
});

// Repository Provider
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((final ref) {
  return SubscriptionRepositoryImpl(ref.watch(subscriptionRemoteDataSourceProvider));
});

// Use Case Provider
final getSubscriptionUseCaseProvider = Provider<GetSubscription>((final ref) {
  return GetSubscription(
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
});

// Subscription Data Provider
final subscriptionProvider = FutureProvider<Subscription>((final ref) async {
  final getSubscriptionUseCase = ref.watch(getSubscriptionUseCaseProvider);
  final result = await getSubscriptionUseCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
});
