import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class LocalDataStore {
  /// Wipes everything kept on the device for the signed-in user: every Isar
  /// collection and the cached image files.
  Future<Result<void, Failure>> clear();
}
