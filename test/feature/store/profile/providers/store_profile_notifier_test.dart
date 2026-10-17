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
  _FakeGetStoreProfile(this.profile);

  final StoreProfile? profile;
  var loads = 0;

  @override
  Future<Result<StoreProfile?, Failure>> call({
    final bool forceRefresh = false,
  }) async {
    loads++;
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

  ProviderContainer makeContainer(final StoreProfile? profile) {
    getProfile = _FakeGetStoreProfile(profile);
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
  save(
    final ProviderContainer container, {
    required final StoreProfile original,
  }) => container
      .read(storeProfileProvider.notifier)
      .save(
        original: original,
        name: 'renamed',
        address: null,
        channels: {StoreChannel.online},
        orderContacts: const [],
      );

  test('save shows the saved profile without refetching', () async {
    final container = makeContainer(storeProfile());
    await container.read(storeProfileProvider.future);

    final result = await save(container, original: storeProfile());

    expect(result.get()!.addressUnresolved, isTrue);
    expect(container.read(storeProfileProvider).value!.name, 'renamed');
    expect(getProfile.loads, 1);
  });

  test(
    'save diffs against the form baseline, not the latest profile',
    () async {
      final container = makeContainer(storeProfile(name: 'renamed elsewhere'));
      await container.read(storeProfileProvider.future);
      final baseline = storeProfile(name: 'seen in the form');

      await save(container, original: baseline);

      expect(update.received!.original, baseline);
    },
  );
}
