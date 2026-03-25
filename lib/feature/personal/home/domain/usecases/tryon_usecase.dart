import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonUseCase {
  TryonUseCase({
    required final UserProfileRepository userProfileRepository,
    required final TryOnRepository tryOnRepository,
  }) : _userProfileRepository = userProfileRepository,
       _tryOnRepository = tryOnRepository;

  final UserProfileRepository _userProfileRepository;
  final TryOnRepository _tryOnRepository;

  /// Performs virtual try-on.
  /// If [params.avatarBase64] is not provided, automatically fetches current user's avatarPath.
  /// This encapsulates the business logic: "use custom avatar if provided, otherwise use current user avatar"
  Future<Result<TryonResult, Failure>> call(final TryOnParams params) async {
    String? avatarPath = params.avatarPath;

    if (params.avatarBase64 == null) {
      final profileResult = await _userProfileRepository.getUserProfile();
      if (profileResult.isFailure) {
        return Err(profileResult.getError()!);
      }
      avatarPath = profileResult.get()!.avatarPath;
    }

    return _tryOnRepository.tryon(params.copyWith(avatarPath: avatarPath));
  }
}
