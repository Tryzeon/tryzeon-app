import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/errors/api_error_code.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/usage_quota/data/mappers/usage_quota_payload.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_response_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/avatar_missing_exception.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/color_unavailable_exception.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/quota_exceeded_exception.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _tryonFunction = 'tryon';
  static const _noAvatarCode = 'NO_AVATAR';
  static const _colorUnavailableCode = 'COLOR_UNAVAILABLE';
  static const _aiGenerationFailedCode = 'AI_GENERATION_FAILED';

  /// Client-side ceilings slightly above the edge function's worst case
  /// (video polls the provider for up to 300s server-side), so a killed
  /// function can never leave the caller waiting forever. The image ceiling
  /// clears the platform's 150s wall-clock kill: giving up sooner drops an
  /// image the server still finishes and charges for.
  static const _imageTimeout = Duration(seconds: 160);
  static const _videoTimeout = Duration(minutes: 7);

  Future<TryonResponseDto> tryon(final TryonFunctionRequest request) async {
    try {
      final response = await _supabase.functions
          .invoke(_tryonFunction, body: request.toJson())
          .timeout(switch (request.mode) {
            TryonMode.video => _videoTimeout,
            TryonMode.image => _imageTimeout,
          });
      return decodeFunctionResponse<TryonResponseDto>(
        response.data,
        TryonResponseDto.fromJson,
      );
    } on FunctionException catch (e) {
      final body = e.details;
      if (body is! Map) rethrow;
      final AppException? translated = switch (body['code']) {
        ApiErrorCode.quotaExceeded => QuotaExceededException(
          quota: tryParseUsageQuotaPayload(body['quota']),
        ),
        _noAvatarCode => const AvatarMissingException(),
        _colorUnavailableCode => const ColorUnavailableException(),
        _aiGenerationFailedCode => const ServerException('AI 無法辨識圖片，請換一張試試'),
        _ => null,
      };
      if (translated != null) throw translated;
      rethrow;
    }
  }
}
