import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wires seasons through repository and shop datasources', () {
    final repository = File(
      'lib/feature/store/products/data/repositories/product_repository_impl.dart',
    ).readAsStringSync();
    final shopRemote = File(
      'lib/feature/personal/shop/data/datasources/shop_remote_datasource.dart',
    ).readAsStringSync();
    final shopLocal = File(
      'lib/feature/personal/shop/data/datasources/shop_local_datasource.dart',
    ).readAsStringSync();

    expect(
      repository,
      contains("seasons: params.seasons?.map((final e) => e.value).toList(),"),
    );
    expect(repository, contains('seasons: params.seasons,'));
    expect(shopRemote, contains('styles, seasons,'));
    expect(shopLocal, contains('..seasons = model.seasons'));
    expect(shopLocal, contains('seasons: collection.seasons,'));
  });
}
