import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/data/dtos/delete_images_request.dart';
import 'package:tryzeon/feature/store/data/dtos/presign_file_dto.dart';
import 'package:tryzeon/feature/store/data/dtos/presign_logo_request.dart';
import 'package:tryzeon/feature/store/data/dtos/presign_products_request.dart';
import 'package:tryzeon/feature/store/data/dtos/presign_products_response_dto.dart';
import 'package:tryzeon/feature/store/data/dtos/presigned_upload_dto.dart';

class StoreImagesApi {
  StoreImagesApi(this._supabaseClient, [final Dio? dio]) : _dio = dio ?? Dio();

  final SupabaseClient _supabaseClient;
  final Dio _dio;

  Future<String> uploadStoreLogo({
    required final String storeId,
    required final File logo,
  }) async {
    final contentType = lookupMimeType(logo.path) ?? 'image/jpeg';
    final bytes = await logo.readAsBytes();

    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesPresignLogo,
      body: PresignLogoRequest(
        storeId: storeId,
        contentType: contentType,
        contentLength: bytes.length,
      ).toJson(),
    );
    final presign = decodeFunctionResponse(
      response.data,
      PresignedUploadDto.fromJson,
    );

    await _putToR2(
      uploadUrl: presign.uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );
    return presign.key;
  }

  Future<List<String>> uploadProductImages({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    if (images.isEmpty) return const [];

    final contentTypes = images
        .map((final f) => lookupMimeType(f.path) ?? 'image/jpeg')
        .toList();
    final allBytes = await Future.wait(
      images.map((final f) => f.readAsBytes()),
    );

    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesPresignProducts,
      body: PresignProductsRequest(
        storeId: storeId,
        productId: productId,
        files: [
          for (var i = 0; i < images.length; i++)
            PresignFileDto(
              contentType: contentTypes[i],
              contentLength: allBytes[i].length,
            ),
        ],
      ).toJson(),
    );
    final items = decodeFunctionResponse(
      response.data,
      PresignProductsResponseDto.fromJson,
    ).items;
    if (items.length != images.length) {
      throw const ServerException(
        'store-images: presign returned wrong number of items',
      );
    }

    final uploadedKeys = <String>[];
    try {
      return await Future.wait(
        List.generate(images.length, (final i) async {
          await _putToR2(
            uploadUrl: items[i].uploadUrl,
            bytes: allBytes[i],
            contentType: contentTypes[i],
          );
          return items[i].key;
        }),
        cleanUp: uploadedKeys.add,
      );
    } catch (e) {
      if (uploadedKeys.isNotEmpty) {
        try {
          await deleteImages(storeId: storeId, keys: uploadedKeys);
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Failed to delete partially uploaded images',
            e,
            stackTrace,
          );
        }
      }
      rethrow;
    }
  }

  Future<void> deleteImages({
    required final String storeId,
    required final List<String> keys,
  }) async {
    if (keys.isEmpty) return;
    await _supabaseClient.functions.invoke(
      AppConstants.functionStoreImagesDelete,
      body: DeleteImagesRequest(storeId: storeId, keys: keys).toJson(),
    );
  }

  Future<void> _putToR2({
    required final String uploadUrl,
    required final Uint8List bytes,
    required final String contentType,
  }) async {
    await _dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(contentType: contentType),
    );
  }
}
