import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/geo_coordinates.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/services/store_logo_storage.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements StoreProfileRepository {
  Result<void, Failure> updateResult = const Ok(null);
  StoreProfile? savedTarget;

  @override
  Future<Result<void, Failure>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
  }) async {
    savedTarget = target;
    return updateResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeLogoStorage implements StoreLogoStorage {
  Result<String, Failure> uploadResult = const Ok('logos/new.png');
  final List<String> deleted = [];

  @override
  Future<Result<String, Failure>> upload({
    required final String storeId,
    required final File logo,
  }) async => uploadResult;

  @override
  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final String path,
  }) async {
    deleted.add(path);
    return const Ok(null);
  }
}

class _FakeGeocoding implements GeocodingService {
  Result<GeoCoordinates?, Failure> result = const Ok((
    latitude: 25.03,
    longitude: 121.56,
  ));
  final List<String> queried = [];

  @override
  Future<Result<GeoCoordinates?, Failure>> geocodeAddress(
    final String address,
  ) async {
    queried.add(address);
    return result;
  }
}

void main() {
  late _FakeRepository repository;
  late _FakeLogoStorage logoStorage;
  late _FakeGeocoding geocoding;
  late UpdateStoreProfile updateStoreProfile;

  final original = StoreProfile(
    id: 's1',
    ownerId: 'o1',
    name: '舊店名',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    channels: const {StoreChannel.physical},
    logoPath: 'logos/old.png',
    address: '台北市信義區',
    latitude: 25.0,
    longitude: 121.5,
  );
  const draft = StoreProfileDraft(
    name: '新店名',
    channels: {StoreChannel.physical},
    address: '台北市信義區',
  );

  setUp(() {
    repository = _FakeRepository();
    logoStorage = _FakeLogoStorage();
    geocoding = _FakeGeocoding();
    updateStoreProfile = UpdateStoreProfile(
      repository: repository,
      logoStorage: logoStorage,
      geocoding: geocoding,
    );
  });

  test(
    'saves the draft without touching logos when no logo is picked',
    () async {
      final result = await updateStoreProfile(
        UpdateStoreProfileParams(original: original, draft: draft),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.savedTarget!.name, '新店名');
      expect(repository.savedTarget!.logoPath, 'logos/old.png');
      expect(logoStorage.deleted, isEmpty);
    },
  );

  test('deletes the old logo only after the new one is saved', () async {
    final result = await updateStoreProfile(
      UpdateStoreProfileParams(
        original: original,
        draft: draft,
        logoFile: File('n.png'),
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.savedTarget!.logoPath, 'logos/new.png');
    expect(logoStorage.deleted, ['logos/old.png']);
  });

  test('a failed write discards the new logo and keeps the old one', () async {
    repository.updateResult = const Err(ServerFailure());

    final result = await updateStoreProfile(
      UpdateStoreProfileParams(
        original: original,
        draft: draft,
        logoFile: File('n.png'),
      ),
    );

    expect(result.getError(), const ServerFailure());
    expect(logoStorage.deleted, ['logos/new.png']);
  });

  test('a failed upload never writes the profile', () async {
    logoStorage.uploadResult = const Err(ServerFailure());

    final result = await updateStoreProfile(
      UpdateStoreProfileParams(
        original: original,
        draft: draft,
        logoFile: File('n.png'),
      ),
    );

    expect(result.getError(), const ServerFailure());
    expect(repository.savedTarget, isNull);
  });

  group('coordinates', () {
    Future<Result<({bool addressUnresolved}), Failure>> saveAddress(
      final String? address,
    ) => updateStoreProfile(
      UpdateStoreProfileParams(
        original: original,
        draft: draft.copyWith(address: address),
      ),
    );

    test(
      'an unchanged address keeps its coordinates without geocoding',
      () async {
        final result = await saveAddress('台北市信義區');

        expect(result.get(), (addressUnresolved: false));
        expect(geocoding.queried, isEmpty);
        expect(repository.savedTarget!.latitude, 25.0);
        expect(repository.savedTarget!.longitude, 121.5);
      },
    );

    test('a new address is geocoded', () async {
      final result = await saveAddress('台北市大安區');

      expect(result.get(), (addressUnresolved: false));
      expect(geocoding.queried, ['台北市大安區']);
      expect(repository.savedTarget!.latitude, 25.03);
      expect(repository.savedTarget!.longitude, 121.56);
    });

    test('a new address with no match saves without coordinates', () async {
      geocoding.result = const Ok(null);

      final result = await saveAddress('不存在的地址');

      expect(result.get(), (addressUnresolved: true));
      expect(repository.savedTarget!.latitude, isNull);
    });

    test('a geocoder failure still saves, flagged as unresolved', () async {
      geocoding.result = const Err(UnknownFailure());

      final result = await saveAddress('台北市大安區');

      expect(result.get(), (addressUnresolved: true));
      expect(repository.savedTarget!.longitude, isNull);
    });

    test('a cleared address drops the coordinates', () async {
      final result = await saveAddress(null);

      expect(result.get(), (addressUnresolved: false));
      expect(geocoding.queried, isEmpty);
      expect(repository.savedTarget!.latitude, isNull);
    });
  });
}
