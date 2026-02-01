import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:tryzeon/feature/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';
import 'package:tryzeon/feature/subscription/domain/repositories/subscription_repository.dart';
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

// Controller Provider
// Subscription Data Provider
final subscriptionProvider = FutureProvider<Subscription>((final ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final result = await ref
      .read(subscriptionRepositoryProvider)
      .getSubscription(profile.userId);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
});
