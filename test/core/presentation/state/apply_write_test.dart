import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/apply_write.dart';
import 'package:typed_result/typed_result.dart';

class _Owner extends AsyncNotifier<int> with ApplyWrite<int> {
  static Future<int> Function() onBuild = () async => 1;
  static var builds = 0;

  @override
  Future<int> build() {
    builds++;
    return onBuild();
  }

  Future<Result<int, Failure>> write(
    final Future<Result<int, Failure>> Function() write, {
    final int? Function(int current, int written)? merge,
  }) => applyWrite(
    write,
    merge: merge ?? (final current, final written) => current + written,
  );
}

final _ownerProvider = AsyncNotifierProvider<_Owner, int>(_Owner.new);
final _disposableOwnerProvider = AsyncNotifierProvider.autoDispose<_Owner, int>(
  _Owner.new,
);

void main() {
  late ProviderContainer container;

  setUp(() {
    _Owner.onBuild = () async => 1;
    _Owner.builds = 0;
    container = ProviderContainer(retry: (final _, final _) => null);
    addTearDown(container.dispose);
  });

  Future<void> mount() async {
    container.listen(_ownerProvider, (final _, final _) {});
    try {
      await container.read(_ownerProvider.future);
    } on Failure {
      return;
    }
  }

  _Owner owner() => container.read(_ownerProvider.notifier);

  test('success merges the written value without rebuilding', () async {
    await mount();

    final result = await owner().write(() async => const Ok(5));

    expect(result.get(), 5);
    expect(container.read(_ownerProvider), const AsyncData(6));
    expect(_Owner.builds, 1);
  });

  test('failure leaves the state untouched', () async {
    await mount();

    final result = await owner().write(() async => const Err(NetworkFailure()));

    expect(result.getError(), isA<NetworkFailure>());
    expect(container.read(_ownerProvider), const AsyncData(1));
    expect(_Owner.builds, 1);
  });

  test('with no value yet, success rebuilds instead of merging', () async {
    _Owner.onBuild = () async => throw const ServerFailure();
    await mount();
    expect(container.read(_ownerProvider).hasError, isTrue);
    var merged = false;
    _Owner.onBuild = () async => 9;

    await owner().write(
      () async => const Ok(5),
      merge: (final current, final written) {
        merged = true;
        return current + written;
      },
    );

    expect(await container.read(_ownerProvider.future), 9);
    expect(merged, isFalse);
  });

  test(
    'a write landing during a rebuild rebuilds again instead of merging',
    () async {
      await mount();
      final inFlight = Completer<int>();
      _Owner.onBuild = () => inFlight.future;
      container.invalidate(_ownerProvider);
      expect(container.read(_ownerProvider).isLoading, isTrue);

      await owner().write(() async => const Ok(5));
      _Owner.onBuild = () async => 3;
      inFlight.complete(2);

      expect(await container.read(_ownerProvider.future), 3);
    },
  );

  test('a write landing on an error that kept old data rebuilds', () async {
    await mount();
    _Owner.onBuild = () async => throw const ServerFailure();
    container.invalidate(_ownerProvider);
    await mount();
    expect(container.read(_ownerProvider).hasError, isTrue);
    expect(container.read(_ownerProvider).hasValue, isTrue);
    _Owner.onBuild = () async => 7;

    await owner().write(() async => const Ok(5));

    expect(await container.read(_ownerProvider.future), 7);
  });

  test('merge returning null rebuilds', () async {
    await mount();
    _Owner.onBuild = () async => 7;

    await owner().write(
      () async => const Ok(5),
      merge: (final _, final _) => null,
    );

    expect(await container.read(_ownerProvider.future), 7);
    expect(_Owner.builds, 2);
  });

  test('a write that lands after the provider rebuilt is dropped', () async {
    await mount();
    final pending = Completer<Result<int, Failure>>();

    final write = owner().write(() => pending.future);
    _Owner.onBuild = () async => 3;
    container.invalidate(_ownerProvider);
    await container.read(_ownerProvider.future);
    pending.complete(const Ok(5));
    await write;

    expect(container.read(_ownerProvider), const AsyncData(3));
  });

  test('keeps an unlistened owner alive until the write lands', () async {
    final sub = container.listen(
      _disposableOwnerProvider,
      (final _, final _) {},
    );
    await container.read(_disposableOwnerProvider.future);
    final notifier = container.read(_disposableOwnerProvider.notifier);
    sub.close();
    final pending = Completer<Result<int, Failure>>();

    final write = notifier.write(() => pending.future);
    await container.pump();
    pending.complete(const Ok(5));
    await write;

    expect(container.read(_disposableOwnerProvider), const AsyncData(6));
    expect(_Owner.builds, 1);
  });
}
