import 'package:json_annotation/json_annotation.dart';

part 'daily_usage_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DailyUsageDto {
  const DailyUsageDto({
    required this.userId,
    required this.usageDate,
    required this.tryonCount,
    required this.chatCount,
    required this.videoCount,
  });

  factory DailyUsageDto.fromJson(final Map<String, dynamic> json) =>
      _$DailyUsageDtoFromJson(json);

  factory DailyUsageDto.empty({
    required final String userId,
    required final DateTime usageDate,
  }) => DailyUsageDto(
    userId: userId,
    usageDate: usageDate,
    tryonCount: 0,
    chatCount: 0,
    videoCount: 0,
  );

  final String userId;
  final DateTime usageDate;
  final int tryonCount;
  final int chatCount;
  final int videoCount;
}
