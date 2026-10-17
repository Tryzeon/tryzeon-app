import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/get_store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../support/store_test_doubles.dart';

class _FakeGetStoreProfile implements GetStoreProfile {
  _FakeGetStoreProfile(this.profile, {this.failure});

  final StoreProfile? profile;
  final Failure? failure;
  var loads = 0;

  @override
  Future<Result<StoreProfile?, Failure>> call({
    final bool forceRefresh = false,
  }) async {
    loads++;
    if (failure case final failure?) return Err(failure);
    return Ok(profile);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUpdateStoreProfile implements UpdateStoreProfile {
  UpdateStoreProfileParams? received;

  @override
  Future<Result<({StoreProfile profile, bool addressUnresolved}), Failure>>
  call(final UpdateStoreProfileParams params) async {
    received = params;
    return Ok((
      profile: params.original.applyDraft(params.draft),
      addressUnresolved: true,
    ));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeGetStoreProfile getProfile;
  late _FakeUpdateStoreProfile update;

  ProviderContainer makeContainer(
    final StoreProfile? profile, {
    final Failure? failure,
  }) {
    getProfile = _FakeGetStoreProfile(profile, failure: failure);
    update = _FakeUpdateStoreProfile();
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        getStoreProfileUseCaseProvider.overrideWithValue(getProfile),
        updateStoreProfileUseCaseProvider.overrideWithValue(update),
      ],
    );
    addTearDown(container.dispose);
    container.listen(storeProfileProvider, (final _, final _) {});
    return container;
  }

  Future<Result<({StoreProfile profile, bool addressUnresolved}), Failure>>
  save(final ProviderContainer container) => container
      .read(storeProfileProvider.notifier)
      .save(
        name: 'renamed',
        address: null,
        channels: {StoreChannel.online},
        orderContacts: const [],
      );

  test('save shows the saved profile without refetching', () async {
    final container = makeContainer(storeProfile());
    await container.read(storeProfileProvider.future);

    final result = await save(container);

    expect(result.get()!.addressUnresolved, isTrue);
    expect(container.read(storeProfileProvider).value!.name, 'renamed');
    expect(update.received!.original, storeProfile());
    expect(getProfile.loads, 1);
  });

  test('save without a profile fails with AuthFailure', () async {
    final container = makeContainer(null);
    await container.read(storeProfileProvider.future);

    final result = await save(container);

    expect(result.getError(), isA<AuthFailure>());
    expect(update.received, isNull);
  });

  test('save while the profile failed to load returns that failure', () async {
    final container = makeContainer(null, failure: const NetworkFailure());
    await container
        .read(storeProfileProvider.future)
        .catchError((final _) => null);

    final result = await save(container);

    expect(result.getError(), isA<NetworkFailure>());
    expect(update.received, isNull);
  });
}
