import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/failures/color_unavailable_failure.dart';

class ColorUnavailableException extends AppException {
  const ColorUnavailableException();

  @override
  Failure toFailure() => const ColorUnavailableFailure();
}
