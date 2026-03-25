import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import '../../domain/entities/tryon_params.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> tryon(final TryOnParams params) async {
    final Map<String, dynamic> body = {};
    body['avatarBase64'] = params.avatarBase64;
    body['avatarPath'] = params.avatarPath;
    body['clothesBase64'] = params.clothesBase64;
    body['clothesPath'] = params.clothesPath;

    body[AppConstants.paramMode] = params.mode.name;

    if (params.scenePrompt != null && params.scenePrompt!.isNotEmpty) {
      body[AppConstants.paramScenePrompt] = params.scenePrompt;
    }
    if (params.transitionPrompt != null && params.transitionPrompt!.isNotEmpty) {
      body[AppConstants.paramTransitionPrompt] = params.transitionPrompt;
    }

    final response = await _supabase.functions.invoke(
      AppConstants.functionTryon,
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }
}
