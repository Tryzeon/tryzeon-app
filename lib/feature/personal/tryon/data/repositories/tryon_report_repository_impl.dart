import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_report_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_report_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonReportRepositoryImpl implements TryonReportRepository {
  TryonReportRepositoryImpl({
    required final TryonReportRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final TryonReportRemoteDataSource _remoteDataSource;

  static const _uniqueViolation = '23505';

  @override
  Future<Result<void, Failure>> report(final String tryonId) async {
    try {
      await _remoteDataSource.report(tryonId);
      return const Ok(null);
    } catch (e, stackTrace) {
      // One try-on takes one report, so a duplicate means an earlier attempt
      // landed and only its response was lost.
      if (e is PostgrestException && e.code == _uniqueViolation) {
        return const Ok(null);
      }
      AppLogger.error('Try-on report failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
