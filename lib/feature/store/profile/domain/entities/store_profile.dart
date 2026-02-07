import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_profile.freezed.dart';

@freezed
sealed class StoreProfile with _$StoreProfile {
  const factory StoreProfile({
    required final String id,
    required final String ownerId,
    required final String name,
    final String? address,
    final String? logoPath,
    final String? logoUrl,
  }) = _StoreProfile;
}
