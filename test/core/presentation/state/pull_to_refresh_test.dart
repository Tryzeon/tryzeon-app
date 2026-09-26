import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:typed_result/typed_result.dart';

class _Counter extends AsyncNotifier<int> with PullToRefresh<int> {
  static Future<int> Function() onBuild = () async => 1;

  @override
  Future<int> build() => onBuild();

  Future<Result<void, Failure>> refresh(
    final Future<Result<int, Failure>> Function() fetch,
  ) => applyRefresh(fetch);
}

final _counterProvider = AsyncNotifierProvider<_Counter, int>(_Counter.new);

void main() {
  late ProviderContainer container;

  setUp(() {
    _Counter.onBuild = () async => 1;
    container = ProviderContainer(retry: (final _, final _) => null);
    addTearDown(container.dispose);
  });

  Future<void> mount() async {
    container.listen(_counterProvider, (final _, final _) {});
    try {
      await container.read(_counterProvider.future);
    } on Failure {
      return;
    }
  }

  _Counter notifier() => container.read(_counterProvider.notifier);

  test('success replaces the data', () async {
    await mount();

    final result = await notifier().refresh(() async => const Ok(2));

    expect(result.isSuccess, isTrue);
    expect(container.read(_counterProvider), const AsyncData(2));
  });

  test('failure keeps the data on screen and reports the failure', () async {
    await mount();

    final result = await notifier().refresh(() async => const Err(NetworkFailure()));

    expect(result.getError(), isA<NetworkFailure>());
    expect(container.read(_counterProvider), const AsyncData(1));
  });

  test('failure with no data to keep surfaces as an error state', () async {
    _Counter.onBuild = () async => throw const ServerFailure();
    await mount();
    expect(container.read(_counterProvider).hasError, isTrue);

    final result = await notifier().refresh(() async => const Err(NetworkFailure()));

    expect(result.getError(), isA<NetworkFailure>());
    final state = container.read(_counterProvider);
    expect(state.hasValue, isFalse);
    expect(state.error, isA<NetworkFailure>());
  });

  test('a result that lands after the provider rebuilt is dropped', () async {
    await mount();
    final fetch = Completer<Result<int, Failure>>();

    final refresh = notifier().refresh(() => fetch.future);
    _Counter.onBuild = () async => 3;
    container.invalidate(_counterProvider);
    await container.read(_counterProvider.future);
    fetch.complete(const Ok(2));
    await refresh;

    expect(container.read(_counterProvider), const AsyncData(3));
  });
}
