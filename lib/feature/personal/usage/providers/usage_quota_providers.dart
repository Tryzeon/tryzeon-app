import 'dart:async';

import 'package:clock/clock.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
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
  // The store reports a purchase before the RevenueCat webhook updates our
  // tables, so the first re-read can still return the old plan.
  static const _planChangeReReadDelays = [
    Duration(seconds: 3),
    Duration(seconds: 13),
  ];

  // The server rolls over on its own clock; re-reading a moment past the
  // reset keeps the request from landing just before it.
  static const _resetGrace = Duration(seconds: 5);

  final _planChangeReReads = <Timer>[];
  Timer? _resetRefresh;

  @override
  Future<UsageQuota> build() async {
    ref.watch(isAuthenticatedProvider);
    listenSelf((final _, final next) {
      if (next case AsyncData(:final value)) {
        _scheduleResetRefresh(value.resetsAt);
      }
    });
    ref.onDispose(_cancelResetRefresh);
    ref.listen<AppSubscriptionTier?>(
      appSubscriptionEntitlementProvider.select(
        (final entitlement) => entitlement.value?.tier,
      ),
      _onEntitlementTierChanged,
    );
    ref.onDispose(_cancelPlanChangeReReads);

    final result = await ref.watch(getUsageQuotaUseCaseProvider)();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() =>
      applyRefresh(() => ref.read(getUsageQuotaUseCaseProvider)());

  void _scheduleResetRefresh(final DateTime resetsAt) {
    _cancelResetRefresh();

    final untilReset = resetsAt.difference(clock.now());
    if (untilReset <= Duration.zero) return;

    _resetRefresh = Timer(untilReset + _resetGrace, () => unawaited(refresh()));
  }

  void _cancelResetRefresh() {
    _resetRefresh?.cancel();
    _resetRefresh = null;
  }

  void _onEntitlementTierChanged(
    final AppSubscriptionTier? previous,
    final AppSubscriptionTier? next,
  ) {
    if (previous == null || next == null || previous == next) return;
    _cancelPlanChangeReReads();
    unawaited(refresh());
    for (final delay in _planChangeReReadDelays) {
      _planChangeReReads.add(
        Timer(delay, () {
          if (state.value?.tier != next) unawaited(refresh());
        }),
      );
    }
  }

  void _cancelPlanChangeReReads() {
    for (final timer in _planChangeReReads) {
      timer.cancel();
    }
    _planChangeReReads.clear();
  }
}

/// The server enforces the video quota, so an unknown snapshot must not hide
/// a feature the user may have paid for.
@riverpod
bool hasVideoAccess(final Ref ref) => ref.watch(
  usageQuotaProvider.select(
    (final async) => async.value?.hasVideoAccess != false,
  ),
);
