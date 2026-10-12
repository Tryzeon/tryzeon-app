import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';
import 'package:tryzeon/feature/store/profile/data/mappers/store_profile_mappr.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

void main() {
  const mappr = StoreProfileMappr();

  Map<String, dynamic> profileRow({final String? logoPath}) => {
    'id': 's1',
    'owner_id': 'u1',
    'name': '小店',
    'channels': const <String>[],
    'logo_path': logoPath,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  test('store logo URL is derived from the logo path', () {
    final profile = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: 's1/logo.png')),
    );

    expect(profile.logoUrl, PublicImageUrl.of('s1/logo.png'));
  });

  test('a blank logo path yields no logo URL', () {
    final fromDto = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: '')),
    );
    final fromCache = mappr.convert<StoreProfileCache, StoreProfile>(
      StoreProfileCache()
        ..storeId = 's1'
        ..ownerId = 'u1'
        ..name = '小店'
        ..channels = []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );

    expect(fromDto.logoUrl, isNull);
    expect(fromCache.logoUrl, isNull);
  });

  test('entity to DTO serializes the path, never a URL', () {
    final profile = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow(logoPath: 's1/logo.png')),
    );

    final json = mappr.convert<StoreProfile, StoreProfileDto>(profile).toJson();

    expect(json['logo_path'], 's1/logo.png');
    expect(json.containsKey('logo_url'), isFalse);
  });

  test('update payloads leave out server-owned columns', () {
    final profile = mappr.convert<StoreProfileDto, StoreProfile>(
      StoreProfileDto.fromJson(profileRow()),
    );

    final json = mappr.convert<StoreProfile, StoreProfileDto>(profile).toJson();

    expect(json.keys, isNot(anyOf(contains('id'), contains('owner_id'))));
  });
}
