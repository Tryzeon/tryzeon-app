import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/data/dtos/parse_size_voice_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/parse_size_voice_response_dto.dart';
import 'package:tryzeon/feature/store/product/data/mappers/store_product_mappr.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/services/size_voice_parser.dart';
import 'package:typed_result/typed_result.dart';

class SizeVoiceParserImpl implements SizeVoiceParser {
  SizeVoiceParserImpl(this._supabase);

  final SupabaseClient _supabase;
  static const _parseSizeVoiceFunction = 'parse-size-voice';
  static const _timeout = Duration(seconds: 30);
  static const _mappr = StoreProductMappr();

  @override
  Future<Result<List<ParsedSize>, Failure>> parse({
    required final Uint8List audioBytes,
    required final String mimeType,
  }) async {
    try {
      final response = await _supabase.functions
          .invoke(
            _parseSizeVoiceFunction,
            body: ParseSizeVoiceRequest(
              audioBase64: base64Encode(audioBytes),
              mimeType: mimeType,
            ).toJson(),
          )
          .timeout(_timeout);

      final dto = decodeFunctionResponse(
        response.data,
        ParseSizeVoiceResponseDto.fromJson,
      );
      return Ok(_mappr.convertList<ParsedSizeDto, ParsedSize>(dto.sizes));
    } catch (e, stackTrace) {
      AppLogger.error('Size voice parse failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
