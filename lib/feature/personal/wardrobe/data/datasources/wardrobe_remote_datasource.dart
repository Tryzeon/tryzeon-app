import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';

import 'package:tryzeon/feature/personal/wardrobe/data/dtos/update_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/wardrobe_item_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/exceptions/wardrobe_full_exception.dart';

class WardrobeRemoteDataSource {
  WardrobeRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  static const _wardrobeItemTable = 'wardrobe_items';
  static const _bucket = 'wardrobe-images';
  static const _itemColumns =
      'id, image_path, garment_type, tags, created_at, updated_at';

  /// SQLSTATE the wardrobe_items insert trigger raises for a full wardrobe.
  static const _wardrobeFullCode = 'TZ001';

  Future<List<WardrobeItemDto>> getWardrobeItems() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_wardrobeItemTable)
        .select(_itemColumns)
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((final e) {
      return WardrobeItemDto.fromJson(
        Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
      );
    }).toList();
  }

  Future<WardrobeItemDto> createWardrobeItem(
    final CreateWardrobeItemRequest request,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    try {
      final response = await _supabaseClient
          .from(_wardrobeItemTable)
          .insert(request.toJson())
          .select(_itemColumns)
          .single();
      return WardrobeItemDto.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == _wardrobeFullCode) throw const WardrobeFullException();
      rethrow;
    }
  }

  Future<void> deleteWardrobeItem(final String id) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    await _supabaseClient
        .from(_wardrobeItemTable)
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<WardrobeItemDto> updateWardrobeItem({
    required final String id,
    required final UpdateWardrobeItemRequest request,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_wardrobeItemTable)
        .update(request.toJson())
        .eq('id', id)
        .eq('user_id', user.id)
        .select(_itemColumns)
        .single();

    return WardrobeItemDto.fromJson(response);
  }

  Future<String> uploadImage({
    required final String fileName,
    required final Uint8List bytes,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final imagePath = '${user.id}/$fileName';
    final contentType = lookupMimeType(fileName);

    await _supabaseClient.storage
        .from(_bucket)
        .uploadBinary(
          imagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return imagePath;
  }

  Future<void> deleteImage(final String path) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    await _supabaseClient.storage.from(_bucket).remove([path]);
  }

  Future<String> createSignedUrl(final String path) async {
    return _supabaseClient.storage
        .from(_bucket)
        .createSignedUrl(path, AppConstants.signedUrlTtlSeconds);
  }
}
