import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({required final TryonRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TryonRemoteDataSource _remoteDataSource;

  @override
  Future<Result<TryonResult, Failure>> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    try {
      final imageBase64 = await _remoteDataSource.tryon(
        avatarBase64: avatarBase64,
        avatarPath: avatarPath,
        clothesBase64: clothesBase64,
        clothesPath: clothesPath,
      );

      return Ok(TryonResult(imageBase64: imageBase64));
    } catch (e, stackTrace) {
      AppLogger.error('Virtual try-on failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
