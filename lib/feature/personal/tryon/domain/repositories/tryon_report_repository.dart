import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryonReportRepository {
  Future<Result<void, Failure>> report(final String tryonId);
}
