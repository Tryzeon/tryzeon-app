import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/home/domain/usecases/tryon_usecase.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

part 'home_providers.g.dart';

// Data Source Providers
@riverpod
TryonRemoteDataSource tryonRemoteDataSource(final Ref ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
}

// Repository Providers
@riverpod
TryOnRepository tryOnRepository(final Ref ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryOnRepositoryImpl(remoteDataSource: tryonDataSource);
}

// Use Case Providers
@riverpod
TryonUseCase tryonUseCase(final Ref ref) {
  final userProfileRepository = ref.watch(userProfileRepositoryProvider);
  final tryOnRepository = ref.watch(tryOnRepositoryProvider);
  return TryonUseCase(
    userProfileRepository: userProfileRepository,
    tryOnRepository: tryOnRepository,
  );
}
