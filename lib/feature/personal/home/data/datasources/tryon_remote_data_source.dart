import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import '../../domain/entities/tryon_mode.dart';

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
    required final TryOnMode mode,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) async {
    final Map<String, dynamic> body = {};
    body['avatarBase64'] = avatarBase64;
    body['avatarPath'] = avatarPath;
    body['clothesBase64'] = clothesBase64;
    body['clothesPath'] = clothesPath;

    body[AppConstants.paramMode] = mode.name;

    if (scenePrompt != null && scenePrompt.isNotEmpty) {
      body[AppConstants.paramScenePrompt] = scenePrompt;
    }
    if (transitionPrompt != null && transitionPrompt.isNotEmpty) {
      body[AppConstants.paramTransitionPrompt] = transitionPrompt;
    }

    final response = await _supabase.functions.invoke(
      AppConstants.functionTryon,
      body: body,
    );
    return response.data as Map<String, dynamic>;
  }
}
