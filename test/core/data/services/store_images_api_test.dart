import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';

class _FakeFunctions implements FunctionsClient {
  final List<List<String>> deletedKeys = [];

  @override
  dynamic noSuchMethod(final Invocation invocation) {
    final name = invocation.positionalArguments.first as String;
    final body = invocation.namedArguments[#body] as Map<String, dynamic>;
    if (name.contains('delete')) {
      deletedKeys.add(List<String>.from(body['keys'] as List));
      return Future.value(FunctionResponse(data: null, status: 200));
    }
    final files = body['files'] as List;
    return Future.value(
      FunctionResponse(
        status: 200,
        data: {
          'items': [
            for (var i = 0; i < files.length; i++)
              {'key': 'k$i', 'uploadUrl': 'https://r2/$i'},
          ],
        },
      ),
    );
  }
}

class _FakeSupabase implements SupabaseClient {
  _FakeSupabase(this.functions);

  @override
  final FunctionsClient functions;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FailingSecondPutDio implements Dio {
  @override
  dynamic noSuchMethod(final Invocation invocation) {
    final url = invocation.positionalArguments.first as String;
    if (url.endsWith('/1')) {
      return Future<Response<void>>.error(const SocketException('lost'));
    }
    return Future.value(Response<void>(requestOptions: RequestOptions(path: url)));
  }
}

void main() {
  test('a partial upload deletes the keys that did land and rethrows', () async {
    final dir = await Directory.systemTemp.createTemp('store_images');
    addTearDown(() => dir.delete(recursive: true));
    final images = [
      for (var i = 0; i < 3; i++) File('${dir.path}/$i.jpg')..writeAsBytesSync([i]),
    ];
    final functions = _FakeFunctions();
    final api = StoreImagesApi(_FakeSupabase(functions), _FailingSecondPutDio());

    await expectLater(
      api.uploadProductImages(storeId: 's1', productId: 'p1', images: images),
      throwsA(isA<SocketException>()),
    );

    expect(functions.deletedKeys.single, unorderedEquals(['k0', 'k2']));
  });
}
