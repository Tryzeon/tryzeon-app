import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';

class _Upload {
  const _Upload(this.key);

  /// Mirrors a `checked: true` json_serializable factory, which wraps a
  /// missing or mistyped field in a [CheckedFromJsonException].
  factory _Upload.fromJson(final Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String) {
      throw CheckedFromJsonException(json, 'key', '_Upload', 'missing');
    }
    return _Upload(key);
  }

  final String key;
}

void main() {
  test('decodes a well-formed body', () {
    final upload = decodeFunctionResponse({'key': 'k'}, _Upload.fromJson);

    expect(upload.key, 'k');
  });

  test('a body that is not an object is a server error', () {
    expect(
      () => decodeFunctionResponse('oops', _Upload.fromJson),
      throwsA(isA<ServerException>()),
    );
  });

  test('a body with a mistyped field is a server error', () {
    expect(
      () => decodeFunctionResponse({'key': 42}, _Upload.fromJson),
      throwsA(isA<ServerException>()),
    );
  });
}
