import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/usage_quota_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetUsageQuota {
  GetUsageQuota(this._repository);
  final UsageQuotaRepository _repository;

  Future<Result<UsageQuota, Failure>> call() => _repository.getUsageQuota();
}
