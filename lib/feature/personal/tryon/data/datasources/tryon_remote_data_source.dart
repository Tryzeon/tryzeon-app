import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_request_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_response_dto.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  /// Client-side ceilings slightly above the edge function's worst case
  /// (video polls the provider for up to 300s server-side), so a killed
  /// function can never leave the caller waiting forever.
  static const _imageTimeout = Duration(minutes: 2);
  static const _videoTimeout = Duration(minutes: 7);

  Future<TryonResponseDto> tryon(final TryonRequestDto request) async {
    final response = await _supabase.functions
        .invoke(AppConstants.functionTryon, body: request.toJson())
        .timeout(request.isVideo ? _videoTimeout : _imageTimeout);
    return TryonResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}
