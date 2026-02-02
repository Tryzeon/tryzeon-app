import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<String, Failure>> getLLMRecommendation(
    final Map<String, String> answers,
  ) async {
    try {
      final recommendation = await _remoteDataSource.getLLMRecommendation(answers);
      return Ok(recommendation);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get outfit suggestions', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
