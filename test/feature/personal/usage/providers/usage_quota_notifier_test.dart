import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/usage_quota_repository.dart';
import 'package:tryzeon/feature/personal/usage/domain/usecases/get_usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:typed_result/typed_result.dart';

class _QueuedRepository implements UsageQuotaRepository {
  final List<Future<Result<UsageQuota, Failure>>> _responses = [];

  void respond(final Result<UsageQuota, Failure> result) =>
      _responses.add(Future.value(result));

  Completer<Result<UsageQuota, Failure>> respondLater() {
    final completer = Completer<Result<UsageQuota, Failure>>();
    _responses.add(completer.future);
    return completer;
  }

  @override
  Future<Result<UsageQuota, Failure>> getUsageQuota() => _responses.removeAt(0);
}

class _AuthFlag extends Notifier<bool> {
  @override
  bool build() => true;

  void signOut() => state = false;
}

final _authFlagProvider = NotifierProvider<_AuthFlag, bool>(_AuthFlag.new);

UsageQuota _quota({required final int tryonUsed}) => UsageQuota(
  tier: AppSubscriptionTier.pro,
  period: QuotaPeriod.month,
  resetsAt: DateTime.utc(2026, 11, 4, 16),
  tryonImage: FeatureQuota(used: tryonImageUsed, quota: 250),
  tryonVideo: const FeatureQuota(used: 0, quota: 3),
);

void main() {
  late _QueuedRepository repository;
  late ProviderContainer container;

  final initial = _quota(tryonImageUsed: 1);

  setUp(() {
    repository = _QueuedRepository()..respond(Ok(initial));
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith(
          (final ref) => ref.watch(_authFlagProvider),
        ),
        getUsageQuotaUseCaseProvider.overrideWithValue(
          GetUsageQuota(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<UsageQuota> loadInitial() => container.read(usageQuotaProvider.future);

  test('build loads the snapshot through GetUsageQuota', () async {
    expect(await loadInitial(), initial);
  });

  test('refresh replaces state with the fetched snapshot', () async {
    await loadInitial();
    final fresh = _quota(tryonImageUsed: 7);
    repository.respond(Ok(fresh));

    await container.read(usageQuotaProvider.notifier).refresh();

    expect(container.read(usageQuotaProvider).value, fresh);
  });

  test('refresh keeps the current state when the fetch fails', () async {
    await loadInitial();
    repository.respond(const Err(NetworkFailure()));

    await container.read(usageQuotaProvider.notifier).refresh();

    final state = container.read(usageQuotaProvider);
    expect(state.hasError, isFalse);
    expect(state.value, initial);
  });

  group('hasVideoAccess', () {
    test('is granted while no snapshot is known', () {
      repository._responses.clear();
      repository.respondLater();

      expect(container.read(hasVideoAccessProvider), isTrue);
    });

    test('follows the snapshot once it is known', () async {
      repository._responses
        ..clear()
        ..add(
          Future.value(
            Ok(
              UsageQuota(
                tier: AppSubscriptionTier.free,
                period: QuotaPeriod.day,
                resetsAt: _taipeiNov5,
                tryonImage: const FeatureQuota(used: 0, quota: 10),
                tryonVideo: const FeatureQuota(used: 0, quota: 0),
              ),
            ),
          ),
        );
      await loadInitial();

      expect(container.read(hasVideoAccessProvider), isFalse);
    });
  });

  test('a refresh straddling an auth rebuild does not write', () async {
    await loadInitial();
    final pending = repository.respondLater();
    final refresh = container.read(usageQuotaProvider.notifier).refresh();

    final nextUser = _quota(tryonImageUsed: 0);
    repository.respond(Ok(nextUser));
    container.read(_authFlagProvider.notifier).signOut();
    await container.read(usageQuotaProvider.future);

    pending.complete(Ok(_quota(tryonImageUsed: 42)));
    await refresh;

    expect(container.read(usageQuotaProvider).value, nextUser);
  });
}
