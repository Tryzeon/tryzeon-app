import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

part 'store_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreProfileModel {
  const StoreProfileModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.logoPath,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreProfileModel.fromEntity(final StoreProfile entity) {
    return StoreProfileModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      address: entity.address,
      logoPath: entity.logoPath,
      logoUrl: entity.logoUrl,
    );
  }

  factory StoreProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreProfileModelFromJson(json);

  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String? logoPath;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$StoreProfileModelToJson(this);

  StoreProfile toEntity() {
    return StoreProfile(
      id: id,
      ownerId: ownerId,
      name: name,
      address: address,
      logoPath: logoPath,
      logoUrl: logoUrl,
    );
  }
}
