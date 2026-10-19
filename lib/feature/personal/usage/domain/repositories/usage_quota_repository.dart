import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class UsageQuotaRepository {
  Future<Result<UsageQuota, Failure>> getUsageQuota();
}
