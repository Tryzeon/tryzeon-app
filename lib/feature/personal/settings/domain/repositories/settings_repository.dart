import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class SettingsRepository {
  Future<Result<bool, Failure>> getRecommendNearbyShops();
  Future<Result<void, Failure>> setRecommendNearbyShops(final bool value);
}
