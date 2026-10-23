import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/services/size_voice_parser.dart';
import 'package:typed_result/typed_result.dart';

part 'parse_size_voice.freezed.dart';

@freezed
sealed class ParseSizeVoiceParams with _$ParseSizeVoiceParams {
  const factory ParseSizeVoiceParams({
    required final Uint8List audioBytes,
    required final String mimeType,
  }) = _ParseSizeVoiceParams;
}

class ParseSizeVoice {
  ParseSizeVoice(this._parser);

  final SizeVoiceParser _parser;

  Future<Result<List<ParsedSize>, Failure>> call(
    final ParseSizeVoiceParams params,
  ) {
    return _parser.parse(
      audioBytes: params.audioBytes,
      mimeType: params.mimeType,
    );
  }
}
