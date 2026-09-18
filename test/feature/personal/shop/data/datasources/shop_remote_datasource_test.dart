import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';

void main() {
  test('getProduct rejects a malformed id as not found before querying', () {
    final dataSource = ShopRemoteDataSource(SupabaseClient('http://127.0.0.1:1', 'anon'));

    expect(dataSource.getProduct('not-a-uuid'), throwsA(isA<NotFoundException>()));
  });
}
