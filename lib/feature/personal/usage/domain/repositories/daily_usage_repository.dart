import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:typed_result/typed_result.dart';

abstract class DailyUsageRepository {
  Future<Result<DailyUsage, Failure>> getTodayUsage();
}
