import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure({this.quota, final String? message})
    : super(message);

  final UsageQuota? quota;

  @override
  String get defaultMessage => '試穿次數已用完';

  @override
  List<Object?> get props => [message, quota];
}
