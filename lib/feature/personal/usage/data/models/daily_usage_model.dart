import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

part 'daily_usage_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class DailyUsageModel {
  const DailyUsageModel({
    required this.userId,
    required this.usageDate,
    required this.tryonCount,
    required this.chatCount,
    required this.videoCount,
  });

  factory DailyUsageModel.fromJson(final Map<String, dynamic> json) =>
      _$DailyUsageModelFromJson(json);

  factory DailyUsageModel.empty({
    required final String userId,
    required final String usageDate,
  }) => DailyUsageModel(
    userId: userId,
    usageDate: usageDate,
    tryonCount: 0,
    chatCount: 0,
    videoCount: 0,
  );

  final String userId;
  final String usageDate;
  final int tryonCount;
  final int chatCount;
  final int videoCount;

  Map<String, dynamic> toJson() => _$DailyUsageModelToJson(this);

  DailyUsage toEntity() => DailyUsage(
    userId: userId,
    usageDate: DateTime.parse(usageDate),
    tryonCount: tryonCount,
    chatCount: chatCount,
    videoCount: videoCount,
  );
}
