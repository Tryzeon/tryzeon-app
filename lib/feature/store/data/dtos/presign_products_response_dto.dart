import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/data/dtos/presigned_upload_dto.dart';

part 'presign_products_response_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class PresignProductsResponseDto {
  const PresignProductsResponseDto({required this.items});

  factory PresignProductsResponseDto.fromJson(
    final Map<String, dynamic> json,
  ) => _$PresignProductsResponseDtoFromJson(json);

  final List<PresignedUploadDto> items;
}
