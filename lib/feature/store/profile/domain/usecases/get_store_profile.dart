import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetStoreProfile {
  GetStoreProfile(this._repository);
  final StoreProfileRepository _repository;

  Future<Result<StoreProfile?, Failure>> call({final bool forceRefresh = false}) =>
      _repository.getStoreProfile(forceRefresh: forceRefresh);
}
