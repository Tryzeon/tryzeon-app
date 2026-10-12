import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/daily_usage/data/dtos/daily_usage_dto.dart';

part 'tryon_response_dto.g.dart';

/// Server → Client wire response from the `tryon` edge function.
@JsonSerializable(createToJson: false, checked: true)
class TryonResponseDto {
  const TryonResponseDto({this.imageUrl, this.videoUrl, this.usage});

  factory TryonResponseDto.fromJson(final Map<String, dynamic> json) =>
      _$TryonResponseDtoFromJson(json);

  final String? imageUrl;
  final String? videoUrl;
  final DailyUsageDto? usage;
}
