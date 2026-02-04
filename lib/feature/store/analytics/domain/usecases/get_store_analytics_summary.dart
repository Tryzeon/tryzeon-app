import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetStoreAnalyticsSummary {
  GetStoreAnalyticsSummary(this._analyticsRepository, this._profileRepository);

  final StoreAnalyticsRepository _analyticsRepository;
  final StoreProfileRepository _profileRepository;

  Future<Result<StoreAnalyticsSummary, Failure>> call({
    final int? year,
    final int? month,
  }) async {
    final profileResult = await _profileRepository.getStoreProfile();
    if (profileResult.isFailure) {
      return Err(profileResult.getError()!);
    }

    final profile = profileResult.get()!;

    return _analyticsRepository.getStoreAnalyticsSummary(
      profile.id,
      year: year,
      month: month,
    );
  }
}
