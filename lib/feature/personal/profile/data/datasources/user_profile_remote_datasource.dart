import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_avatar_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _userProfileTable = 'user_profiles';
  static const _avatarBucket = 'user-avatars';
  static const _profileColumns =
      'user_id, name, email, avatar_path, avatar_preset, measurements, gender, age_range, style_preferences, is_onboarded, is_tutorial_completed, created_at, updated_at';

  Future<UserProfileDto> getUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .select(_profileColumns)
        .eq('user_id', user.id)
        .single();

    return UserProfileDto.fromJson(response);
  }

  Future<UserProfileDto> updateUserProfile(
    final UpdateUserProfileRequest request,
  ) => _updateRow(request.toJson());

  Future<UserProfileDto> updateAvatar(final UpdateAvatarRequest request) =>
      _updateRow(request.toJson());

  Future<UserProfileDto> _updateRow(final Map<String, dynamic> values) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update(values)
        .eq('user_id', user.id)
        .select(_profileColumns)
        .single();

    return UserProfileDto.fromJson(response);
  }

  Future<String> uploadAvatar(final File image) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final imageName = p.basename(image.path);
    final avatarPath = '${user.id}/avatar/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_avatarBucket)
        .uploadBinary(
          avatarPath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    return avatarPath;
  }

  Future<void> deleteAvatar(final String avatarPath) async {
    await _supabaseClient.storage.from(_avatarBucket).remove([avatarPath]);
  }

  Future<String> createSignedUrl(final String avatarPath) async {
    return _supabaseClient.storage
        .from(_avatarBucket)
        .createSignedUrl(avatarPath, AppConstants.signedUrlTtlSeconds);
  }
}
