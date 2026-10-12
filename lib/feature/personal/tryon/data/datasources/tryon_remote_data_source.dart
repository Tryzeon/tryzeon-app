import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_payload.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_response_dto.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

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
          .invoke(AppConstants.functionTryon, body: request.toJson())
          .timeout(request.isVideo ? _videoTimeout : _imageTimeout);
      return decodeFunctionResponse<TryonResponseDto>(
        response.data,
        TryonResponseDto.fromJson,
      );
    } on FunctionException catch (e) {
      final body = e.details;
      if (body is Map &&
          body['code'] == AppConstants.functionErrorRateLimitExceeded) {
        throw RateLimitException(
          usage: tryParseDailyUsagePayload(body['usage']),
        );
      }
      rethrow;
    }
  }
}
