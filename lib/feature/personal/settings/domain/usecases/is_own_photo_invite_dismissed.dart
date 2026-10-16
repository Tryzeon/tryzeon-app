import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class IsOwnPhotoInviteDismissed {
  IsOwnPhotoInviteDismissed(this._repository);

  final SettingsRepository _repository;

  Future<Result<bool, Failure>> call() =>
      _repository.isOwnPhotoInviteDismissed();
}
