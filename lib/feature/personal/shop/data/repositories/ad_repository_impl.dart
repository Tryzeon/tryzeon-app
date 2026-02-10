import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/ad_repository.dart';
import 'package:typed_result/typed_result.dart';

class AdRepositoryImpl implements AdRepository {
  AdRepositoryImpl(this._adLocalDataSource);

  final AdLocalDataSource _adLocalDataSource;

  @override
  Future<Result<List<String>, Failure>> getAds({final bool forceRefresh = false}) async {
    try {
      final ads = await _adLocalDataSource.getAdImages(forceRefresh: forceRefresh);
      return Ok(ads);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get advertisements', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
