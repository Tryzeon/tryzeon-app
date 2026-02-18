import 'package:json_annotation/json_annotation.dart';

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
}
