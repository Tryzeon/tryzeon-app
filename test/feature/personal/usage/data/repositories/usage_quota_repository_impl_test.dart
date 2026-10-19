import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/data/dtos/usage_quota_dto.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/data/datasources/usage_quota_remote_datasource.dart';
import 'package:tryzeon/feature/personal/usage/data/repositories/usage_quota_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements UsageQuotaRemoteDataSource {
  _FakeRemote({this.dto, this.error});

  final UsageQuotaDto? dto;
  final Object? error;

  @override
  Future<UsageQuotaDto> getUsageQuota() async {
    if (error case final error?) throw error;
    return dto!;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  final resetsAt = DateTime.utc(2026, 11, 4, 16);

  test('maps the snapshot DTO to a UsageQuota', () async {
    final repository = UsageQuotaRepositoryImpl(
      remoteDataSource: _FakeRemote(
        dto: UsageQuotaDto(
          tier: AppSubscriptionTier.pro,
          period: QuotaPeriod.month,
          resetsAt: resetsAt,
          tryonImage: const FeatureQuotaDto(used: 12, quota: 250),
          tryonVideo: const FeatureQuotaDto(used: 1, quota: 3),
        ),
      ),
    );

    final result = await repository.getUsageQuota();

    expect(
      result.get(),
      UsageQuota(
        tier: AppSubscriptionTier.pro,
        period: QuotaPeriod.month,
        resetsAt: resetsAt,
        tryonImage: const FeatureQuota(used: 12, quota: 250),
        tryonVideo: const FeatureQuota(used: 1, quota: 3),
      ),
    );
  });

  test('returns Err when the datasource throws', () async {
    final repository = UsageQuotaRepositoryImpl(
      remoteDataSource: _FakeRemote(error: const UnauthenticatedException()),
    );

    final result = await repository.getUsageQuota();

    expect(result.isFailure, isTrue);
    expect(result.getError(), isA<AuthFailure>());
  });
}
