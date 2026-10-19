import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/tryon/domain/failures/quota_exceeded_failure.dart';

class QuotaExceededException extends AppException {
  const QuotaExceededException({this.quota});

  final UsageQuota? quota;

  @override
  Failure toFailure() => QuotaExceededFailure(quota: quota);
}
