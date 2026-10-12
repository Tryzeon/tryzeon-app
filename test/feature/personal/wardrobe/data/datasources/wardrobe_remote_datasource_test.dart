import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/exceptions/wardrobe_full_exception.dart';

import '../../../../../support/fake_supabase_http.dart';

void main() {
  const request = CreateWardrobeItemRequest(
    id: 'w1',
    imagePath: 'u1/w1.png',
    garmentType: GarmentType.top,
    tags: [],
  );

  Future<void> insertAnswering(final Map<String, dynamic> error) async {
    final client = supabaseAnswering(400, error);
    await signIn(client);
    return WardrobeRemoteDataSource(client).createWardrobeItem(request);
  }

  test('a full wardrobe surfaces as a WardrobeFullException', () async {
    await expectLater(
      insertAnswering({'code': 'TZ001', 'message': 'Wardrobe limit exceeded'}),
      throwsA(isA<WardrobeFullException>()),
    );
  });

  test('any other insert error is rethrown untouched', () async {
    await expectLater(
      insertAnswering({'code': '23505', 'message': 'duplicate key'}),
      throwsA(
        isA<PostgrestException>().having((final e) => e.code, 'code', '23505'),
      ),
    );
  });
}
