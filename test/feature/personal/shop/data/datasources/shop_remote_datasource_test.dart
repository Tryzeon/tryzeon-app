import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';

void main() {
  const productId = '11111111-1111-1111-1111-111111111111';
  const storeId = '22222222-2222-2222-2222-222222222222';

  const storeRow = {
    'id': storeId,
    'name': '小店',
    'slug': 'mia',
    'address': null,
    'logo_path': null,
    'channels': <String>[],
    'order_contacts': [
      {'type': 'line', 'value': '@mia'},
    ],
  };

  late List<Uri> requests;

  ShopRemoteDataSource dataSourceReturning(final Object body) {
    requests = [];
    final client = MockClient((final request) async {
      requests.add(request.url);
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: request,
      );
    });
    return ShopRemoteDataSource(
      SupabaseClient('http://127.0.0.1:1', 'anon', httpClient: client),
    );
  }

  test('getProduct rejects a malformed id as not found before querying', () {
    final dataSource = ShopRemoteDataSource(
      SupabaseClient('http://127.0.0.1:1', 'anon'),
    );

    expect(
      dataSource.getProduct('not-a-uuid'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('getProduct embeds the store order contacts', () async {
    final dataSource = dataSourceReturning({
      'id': productId,
      'name': '碎花洋裝',
      'category_id': 'c1',
      'garment_type': 'one_piece',
      'price': 1280,
      'image_paths': <String>[],
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'product_sizes': <Object>[],
      'store_profiles': storeRow,
    });

    final product = await dataSource.getProduct(productId);

    expect(
      requests.single.queryParameters['select'],
      contains('order_contacts'),
    );
    expect(product.storeInfo.orderContacts.single.type, OrderContactType.line);
    expect(product.storeInfo.orderContacts.single.value, '@mia');
  });

  test('getStoreProfile selects the store order contacts', () async {
    final dataSource = dataSourceReturning(storeRow);

    final store = await dataSource.getStoreProfile('mia');

    expect(
      requests.single.queryParameters['select'],
      contains('order_contacts'),
    );
    expect(store.orderContacts.single.value, '@mia');
  });
}
