import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/usage_quota_repository.dart';
import 'package:tryzeon/feature/personal/usage/domain/usecases/get_usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:typed_result/typed_result.dart';

class _QueuedRepository implements UsageQuotaRepository {
  final List<Future<Result<UsageQuota, Failure>>> _responses = [];
  int calls = 0;

  void respond(final Result<UsageQuota, Failure> result) =>
      _responses.add(Future.value(result));

  Completer<Result<UsageQuota, Failure>> respondLater() {
    final completer = Completer<Result<UsageQuota, Failure>>();
    _responses.add(completer.future);
    return completer;
  }

  @override
  Future<Result<UsageQuota, Failure>> getUsageQuota() {
    calls++;
    return _responses.removeAt(0);
  }
}

class _AuthFlag extends Notifier<bool> {
  @override
  bool build() => true;

  void signOut() => state = false;
}

final _authFlagProvider = NotifierProvider<_AuthFlag, bool>(_AuthFlag.new);

final _taipeiNov5 = DateTime.utc(2026, 11, 4, 16);

UsageQuota _quota({
  required final int tryonImageUsed,
  final AppSubscriptionTier tier = AppSubscriptionTier.pro,
  final DateTime? resetsAt,
}) => UsageQuota(
  tier: tier,
  period: QuotaPeriod.month,
  resetsAt: resetsAt ?? _taipeiNov5,
  tryonImage: FeatureQuota(used: tryonImageUsed, quota: 250),
  tryonVideo: const FeatureQuota(used: 0, quota: 3),
);

AppSubscriptionEntitlement _entitlement(final AppSubscriptionTier tier) =>
    AppSubscriptionEntitlement(tier: tier, expirationDate: null);

void main() {
  late _QueuedRepository repository;
  late StreamController<AppSubscriptionEntitlement> entitlements;
  late ProviderContainer container;

  final initial = _quota(tryonImageUsed: 1);

  setUp(() {
    repository = _QueuedRepository()..respond(Ok(initial));
    entitlements = StreamController<AppSubscriptionEntitlement>.broadcast();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith(
          (final ref) => ref.watch(_authFlagProvider),
        ),
        getUsageQuotaUseCaseProvider.overrideWithValue(
          GetUsageQuota(repository),
        ),
        appSubscriptionEntitlementProvider.overrideWith(
          (final ref) => entitlements.stream,
        ),
      ],
    );
    addTearDown(entitlements.close);
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

  group('after an entitlement tier change', () {
    final freeQuota = _quota(tryonImageUsed: 3, tier: AppSubscriptionTier.free);
    final proQuota = _quota(tryonImageUsed: 0);

    void loadOnFreePlan(final FakeAsync async) {
      repository._responses
        ..clear()
        ..add(Future.value(Ok(freeQuota)));
      container.listen(usageQuotaProvider, (final _, final _) {});
      entitlements.add(_entitlement(AppSubscriptionTier.free));
      async.flushMicrotasks();
      expect(container.read(usageQuotaProvider).value, freeQuota);
      expect(repository.calls, 1);
    }

    void upgradeToPro(final FakeAsync async) {
      entitlements.add(_entitlement(AppSubscriptionTier.pro));
      async.flushMicrotasks();
    }

    test('the first entitlement emission does not refresh', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);

        async.elapse(const Duration(minutes: 1));

        expect(repository.calls, 1);
      });
    });

    test('a tier change refreshes once when the snapshot matches', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);
        repository.respond(Ok(proQuota));

        upgradeToPro(async);

        expect(repository.calls, 2);
        expect(container.read(usageQuotaProvider).value, proQuota);

        async.elapse(const Duration(minutes: 1));
        expect(repository.calls, 2);
      });
    });

    test('a lagging snapshot is re-read after 3s and 13s, then stops', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);
        for (var i = 0; i < 3; i++) {
          repository.respond(Ok(freeQuota));
        }

        upgradeToPro(async);
        expect(repository.calls, 2);

        async.elapse(const Duration(milliseconds: 2999));
        expect(repository.calls, 2);
        async.elapse(const Duration(milliseconds: 1));
        expect(repository.calls, 3);

        async.elapse(const Duration(milliseconds: 9999));
        expect(repository.calls, 3);
        async.elapse(const Duration(milliseconds: 1));
        expect(repository.calls, 4);

        async.elapse(const Duration(minutes: 1));
        expect(repository.calls, 4);
        expect(container.read(usageQuotaProvider).value, freeQuota);
      });
    });

    test('re-reads stop once the snapshot catches up', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);
        repository
          ..respond(Ok(freeQuota))
          ..respond(Ok(proQuota));

        upgradeToPro(async);
        async.elapse(const Duration(seconds: 3));

        expect(repository.calls, 3);
        expect(container.read(usageQuotaProvider).value, proQuota);

        async.elapse(const Duration(minutes: 1));
        expect(repository.calls, 3);
      });
    });

    test('a failed re-read is retried on the same schedule', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);
        repository
          ..respond(const Err(NetworkFailure()))
          ..respond(Ok(proQuota));

        upgradeToPro(async);
        async.elapse(const Duration(seconds: 3));

        expect(repository.calls, 3);
        expect(container.read(usageQuotaProvider).value, proQuota);
      });
    });

    test('a rebuild cancels pending re-reads', () {
      fakeAsync((final async) {
        loadOnFreePlan(async);
        repository.respond(Ok(freeQuota));

        upgradeToPro(async);
        expect(repository.calls, 2);

        repository.respond(Ok(freeQuota));
        container.read(_authFlagProvider.notifier).signOut();
        container.read(usageQuotaProvider);
        async.flushMicrotasks();
        expect(repository.calls, 3);

        async.elapse(const Duration(minutes: 1));
        expect(repository.calls, 3);
      });
    });
  });

  group('at the snapshot reset', () {
    final taipeiDec5 = DateTime.utc(2026, 12, 4, 16);

    void loadAt(final FakeAsync async) {
      repository._responses
        ..clear()
        ..add(Future.value(Ok(initial)));
      container.listen(usageQuotaProvider, (final _, final _) {});
      async.flushMicrotasks();
      expect(container.read(usageQuotaProvider).value, initial);
      expect(repository.calls, 1);
    }

    void runAt(final DateTime now, final void Function(FakeAsync) body) =>
        fakeAsync(body, initialTime: now);

    final hourBeforeReset = _taipeiNov5.subtract(const Duration(hours: 1));

    test('re-reads at resetsAt and schedules the next reset', () {
      runAt(hourBeforeReset, (final async) {
        loadAt(async);
        final nextCycle = _quota(tryonImageUsed: 0, resetsAt: taipeiDec5);
        repository
          ..respond(Ok(nextCycle))
          ..respond(Ok(nextCycle));

        async.elapse(const Duration(hours: 1, seconds: 4));
        expect(repository.calls, 1);
        async.elapse(const Duration(seconds: 1));
        expect(repository.calls, 2);
        expect(container.read(usageQuotaProvider).value, nextCycle);

        async.elapse(taipeiDec5.difference(_taipeiNov5));
        expect(repository.calls, 3);
      });
    });

    test('a resetsAt already past schedules nothing', () {
      runAt(_taipeiNov5.add(const Duration(minutes: 1)), (final async) {
        loadAt(async);

        async.elapse(const Duration(days: 60));

        expect(repository.calls, 1);
      });
    });

    test('a re-read the server has not rolled over yet is not rescheduled', () {
      runAt(hourBeforeReset, (final async) {
        loadAt(async);
        final notRolledOver = _quota(tryonImageUsed: 5);
        repository
          ..respond(Ok(notRolledOver))
          ..respond(Ok(notRolledOver));

        async.elapse(const Duration(hours: 1, seconds: 5));
        expect(repository.calls, 2);
        expect(container.read(usageQuotaProvider).value, notRolledOver);

        async.elapse(const Duration(days: 60));
        expect(repository.calls, 2);
      });
    });

    test('dispose cancels the pending reset re-read', () {
      runAt(hourBeforeReset, (final async) {
        loadAt(async);

        container.dispose();
        async.elapse(const Duration(days: 60));

        expect(repository.calls, 1);
      });
    });

    test('a refresh moves the re-read to the new resetsAt', () {
      runAt(hourBeforeReset, (final async) {
        loadAt(async);
        final later = _taipeiNov5.add(const Duration(hours: 2));
        repository
          ..respond(Ok(_quota(tryonImageUsed: 2, resetsAt: later)))
          ..respond(Ok(_quota(tryonImageUsed: 0, resetsAt: taipeiDec5)));

        unawaited(container.read(usageQuotaProvider.notifier).refresh());
        async.flushMicrotasks();
        expect(repository.calls, 2);

        async.elapse(const Duration(hours: 1, seconds: 5));
        expect(repository.calls, 2);
        async.elapse(const Duration(hours: 2));
        expect(repository.calls, 3);
      });
    });
  });
}
