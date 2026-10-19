import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/data/datasources/usage_quota_remote_datasource.dart';
import 'package:tryzeon/feature/personal/usage/data/repositories/usage_quota_repository_impl.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/usage_quota_repository.dart';
import 'package:tryzeon/feature/personal/usage/domain/usecases/get_usage_quota.dart';
import 'package:typed_result/typed_result.dart';

part 'usage_quota_providers.g.dart';

@riverpod
UsageQuotaRemoteDataSource usageQuotaRemoteDataSource(final Ref ref) =>
    UsageQuotaRemoteDataSource(ref.watch(supabaseClientProvider));

@riverpod
UsageQuotaRepository usageQuotaRepository(final Ref ref) =>
    UsageQuotaRepositoryImpl(
      remoteDataSource: ref.watch(usageQuotaRemoteDataSourceProvider),
    );

@riverpod
GetUsageQuota getUsageQuotaUseCase(final Ref ref) =>
    GetUsageQuota(ref.watch(usageQuotaRepositoryProvider));

@Riverpod(keepAlive: true)
class UsageQuotaNotifier extends _$UsageQuotaNotifier
    with PullToRefresh<UsageQuota> {
  @override
  Future<UsageQuota> build() async {
    ref.watch(isAuthenticatedProvider);

    final result = await ref.watch(getUsageQuotaUseCaseProvider)();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() =>
      applyRefresh(() => ref.read(getUsageQuotaUseCaseProvider)());
}

/// The server enforces the video quota, so an unknown snapshot must not hide
/// a feature the user may have paid for.
@riverpod
bool hasVideoAccess(final Ref ref) => ref.watch(
  usageQuotaProvider.select(
    (final async) => async.value?.hasVideoAccess != false,
  ),
);
