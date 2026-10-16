// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_item_ref_dto.dart';

part 'chat_outfit_dto.freezed.dart';
part 'chat_outfit_dto.g.dart';

@freezed
sealed class ChatOutfitDto with _$ChatOutfitDto {
  @JsonSerializable(checked: true, explicitToJson: true, includeIfNull: false)
  const factory ChatOutfitDto({
    required final String title,
    final String? reason,
    required final List<ChatItemRefDto> pieces,
  }) = _ChatOutfitDto;

  factory ChatOutfitDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatOutfitDtoFromJson(json);
}
