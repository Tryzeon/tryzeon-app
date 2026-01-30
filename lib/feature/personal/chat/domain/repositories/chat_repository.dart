import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class ChatRepository {
  Future<Result<String, Failure>> getLLMRecommendation(final Map<String, String> answers);
}
