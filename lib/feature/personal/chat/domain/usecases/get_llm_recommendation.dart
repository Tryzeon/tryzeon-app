import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetLLMRecommendationUseCase {
  GetLLMRecommendationUseCase(this._repository);
  final ChatRepository _repository;

  Future<Result<String, Failure>> call(final Map<String, String> answers) {
    return _repository.getLLMRecommendation(answers);
  }
}
