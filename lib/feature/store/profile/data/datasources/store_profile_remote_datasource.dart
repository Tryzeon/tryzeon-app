import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileRemoteDataSource {
  StoreProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;
  static const _logoBucket = AppConstants.bucketStoreLogos;

  Future<StoreProfileModel?> getStoreProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select('id, owner_id, name, address, logo_path, created_at, updated_at')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return StoreProfileModel.fromJson(_withLogoUrl(response));
  }

  Future<StoreProfileModel> updateStoreProfile(final StoreProfileModel profile) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final json = profile.toJson()
      ..remove('id')
      ..remove('owner_id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('logo_url');

    final response = await _supabaseClient
        .from(_storeProfileTable)
        .update(json)
        .eq('owner_id', user.id)
        .select()
        .single();

    return StoreProfileModel.fromJson(_withLogoUrl(response));
  }

  Future<String> uploadLogo({
    required final String storeId,
    required final File image,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final imageName = p.basename(image.path);
    final logoPath = '$storeId/logo/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_logoBucket)
        .uploadBinary(logoPath, bytes, fileOptions: FileOptions(contentType: mimeType));

    return logoPath;
  }

  Future<void> deleteLogo(final String logoPath) async {
    await _supabaseClient.storage.from(_logoBucket).remove([logoPath]);
  }

  String _getLogoUrl(final String logoPath) {
    return _supabaseClient.storage.from(_logoBucket).getPublicUrl(logoPath);
  }

  Map<String, dynamic> _withLogoUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null && logoPath.isNotEmpty) {
      map['logo_url'] = _getLogoUrl(logoPath);
    }
    return map;
  }
}
