import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/failures/wardrobe_full_failure.dart';

class WardrobeFullException extends AppException {
  const WardrobeFullException();

  @override
  Failure toFailure() => const WardrobeFullFailure();
}
