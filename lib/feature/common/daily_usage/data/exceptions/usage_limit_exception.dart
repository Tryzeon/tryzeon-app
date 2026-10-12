import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/failures/usage_limit_failure.dart';

class UsageLimitException extends AppException {
  const UsageLimitException({this.usage});

  final DailyUsage? usage;

  @override
  Failure toFailure() => UsageLimitFailure(usage: usage);
}
