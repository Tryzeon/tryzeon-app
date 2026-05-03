import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'chat_recommendation.freezed.dart';

@freezed
sealed class ChatRecommendation with _$ChatRecommendation {
  const factory ChatRecommendation({
    required final String recommendation,
    final DailyUsage? usage,
  }) = _ChatRecommendation;
}
