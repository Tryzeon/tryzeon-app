import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class SizeVoiceParser {
  Future<Result<List<ParsedSize>, Failure>> parse({
    required final Uint8List audioBytes,
    required final String mimeType,
  });
}
