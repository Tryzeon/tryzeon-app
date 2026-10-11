import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/dtos/presigned_upload_dto.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';

void main() {
  test('decodes a well-formed body', () {
    final upload = decodeFunctionResponse({
      'key': 'k',
      'uploadUrl': 'https://r2/k',
    }, PresignedUploadDto.fromJson);

    expect(upload.key, 'k');
    expect(upload.uploadUrl, 'https://r2/k');
  });

  test('a body that is not an object is a server error', () {
    expect(
      () => decodeFunctionResponse('oops', PresignedUploadDto.fromJson),
      throwsA(isA<ServerException>()),
    );
  });

  test('a body missing a field is a server error', () {
    expect(
      () => decodeFunctionResponse({'key': 'k'}, PresignedUploadDto.fromJson),
      throwsA(isA<ServerException>()),
    );
  });
}
