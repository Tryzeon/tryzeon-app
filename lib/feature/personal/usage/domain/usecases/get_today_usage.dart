import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/daily_usage_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetTodayUsage {
  GetTodayUsage(this._repository);
  final DailyUsageRepository _repository;

  Future<Result<DailyUsage, Failure>> call() => _repository.getTodayUsage();
}
