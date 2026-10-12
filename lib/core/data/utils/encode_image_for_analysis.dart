import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

typedef ImageEncoder = Future<String?> Function(File image);

/// Base64 JPEG for the `ImageAnalysisRequest` body. Null when the image cannot
/// be compressed.
Future<String?> encodeImageForAnalysis(final File image) async {
  final jpeg = await FlutterImageCompress.compressWithFile(
    image.path,
    minWidth: 768,
    minHeight: 768,
    quality: 80,
    format: CompressFormat.jpeg,
  );
  return jpeg == null ? null : base64Encode(jpeg);
}
