import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/failures/avatar_missing_failure.dart';

class AvatarMissingException extends AppException {
  const AvatarMissingException();

  @override
  Failure toFailure() => const AvatarMissingFailure();
}
