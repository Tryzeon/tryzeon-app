import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateStoreProfile {
  UpdateStoreProfile(this._repository);
  final StoreProfileRepository _repository;

  Future<Result<void, Failure>> call({
    required final StoreProfile target,
    final File? logoFile,
  }) async {
    final originalResult = await _repository.getStoreProfile();

    if (originalResult.isFailure) {
      return Err(originalResult.getError()!);
    }

    final original = originalResult.get();
    if (original == null) {
      return const Err(ServerFailure('Store profile not found'));
    }

    return _repository.updateStoreProfile(
      original: original,
      target: target,
      logoFile: logoFile,
    );
  }
}
