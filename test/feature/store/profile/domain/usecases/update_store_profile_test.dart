import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
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

void main() {
  late _FakeRepository repository;
  late _FakeLogoStorage logoStorage;
  late UpdateStoreProfile updateStoreProfile;

  final original = StoreProfile(
    id: 's1',
    ownerId: 'o1',
    name: '舊店名',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    channels: const {StoreChannel.physical},
    logoPath: 'logos/old.png',
  );
  const draft = StoreProfileDraft(name: '新店名', channels: {StoreChannel.physical});

  setUp(() {
    repository = _FakeRepository();
    logoStorage = _FakeLogoStorage();
    updateStoreProfile = UpdateStoreProfile(
      repository: repository,
      logoStorage: logoStorage,
    );
  });

  test('saves the draft without touching logos when no logo is picked', () async {
    final result = await updateStoreProfile(
      UpdateStoreProfileParams(original: original, draft: draft),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.savedTarget!.name, '新店名');
    expect(repository.savedTarget!.logoPath, 'logos/old.png');
    expect(logoStorage.deleted, isEmpty);
  });

  test('deletes the old logo only after the new one is saved', () async {
    final result = await updateStoreProfile(
      UpdateStoreProfileParams(original: original, draft: draft, logoFile: File('n.png')),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.savedTarget!.logoPath, 'logos/new.png');
    expect(logoStorage.deleted, ['logos/old.png']);
  });

  test('a failed write discards the new logo and keeps the old one', () async {
    repository.updateResult = const Err(ServerFailure());

    final result = await updateStoreProfile(
      UpdateStoreProfileParams(original: original, draft: draft, logoFile: File('n.png')),
    );

    expect(result.getError(), const ServerFailure());
    expect(logoStorage.deleted, ['logos/new.png']);
  });

  test('a failed upload never writes the profile', () async {
    logoStorage.uploadResult = const Err(ServerFailure());

    final result = await updateStoreProfile(
      UpdateStoreProfileParams(original: original, draft: draft, logoFile: File('n.png')),
    );

    expect(result.getError(), const ServerFailure());
    expect(repository.savedTarget, isNull);
  });
}
