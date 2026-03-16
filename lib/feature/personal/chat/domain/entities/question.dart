import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';

@freezed
sealed class Question with _$Question {
  const factory Question({
    required final String id,
    required final String text,
    required final List<String> quickReplies,
  }) = _Question;
}
