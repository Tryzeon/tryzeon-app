// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_recommended_item_dto.freezed.dart';
part 'chat_recommended_item_dto.g.dart';

@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
sealed class ChatRecommendedItemDto with _$ChatRecommendedItemDto {
  @JsonSerializable(checked: true)
  const factory ChatRecommendedItemDto.product({required final String id}) =
      ChatRecommendedProductDto;

  @JsonSerializable(checked: true)
  const factory ChatRecommendedItemDto.wardrobe({required final String id}) =
      ChatRecommendedWardrobeDto;

  const factory ChatRecommendedItemDto.unknown() = ChatRecommendedUnknownDto;

  factory ChatRecommendedItemDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatRecommendedItemDtoFromJson(json);
}
