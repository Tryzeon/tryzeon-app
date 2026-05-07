import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(
    final BuildContext context, {
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
    final bool enableCrop = false,
    final CropStyle cropStyle = CropStyle.rectangle,
    final List<CropAspectRatioPreset>? aspectRatioPresets,
  }) async {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    final ImageSource? source = await showModalBottomSheet<ImageSource?>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '選擇圖片來源',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('從相簿選擇'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍攝新照片'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return null;

      String sourcePath = pickedFile.path;

      if (enableCrop) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: sourcePath,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '編輯圖片',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: primaryColor,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              cropStyle: cropStyle,
              aspectRatioPresets:
                  aspectRatioPresets ??
                  [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            ),
            IOSUiSettings(
              title: '編輯圖片',
              cropStyle: cropStyle,
              aspectRatioPresets:
                  aspectRatioPresets ??
                  [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
            ),
          ],
        );

        if (croppedFile == null) return null;
        sourcePath = croppedFile.path;
      }

      // Generate timestamp based filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '$timestamp.jpg';

      // Get temp dir
      final Directory directory = await getTemporaryDirectory();
      final String newPath = '${directory.path}/$newFileName';

      // Compress and convert to JPG
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        newPath,
        quality: imageQuality,
        format: CompressFormat.jpeg,
        minWidth: maxWidth.toInt(),
        minHeight: maxHeight.toInt(),
      );

      if (compressedFile == null) return null;
      return File(compressedFile.path);
    } catch (e, stackTrace) {
      AppLogger.error('Pick image failed', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '選擇圖片失敗，請稍後再試');
      }
    }

    return null;
  }

  static Future<List<File>?> pickImages(
    final BuildContext context, {
    final int maxImages = 3,
    final double maxWidth = 1080,
    final double maxHeight = 1920,
    final int imageQuality = 85,
  }) async {
    try {
      if (maxImages <= 0) return null;

      // The pickMultiImage method enforces a limit >= 2.
      // If we only need 1 image, fallback to pickImage single selection.
      if (maxImages == 1) {
        final File? singleFile = await pickImage(
          context,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          enableCrop: false,
        );
        return singleFile != null ? [singleFile] : null;
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(limit: maxImages);

      if (pickedFiles.isEmpty) return null;

      final List<XFile> limitedFiles = pickedFiles.length > maxImages
          ? pickedFiles.sublist(0, maxImages)
          : pickedFiles;

      final List<File> processedFiles = [];

      for (final pickedFile in limitedFiles) {
        final String sourcePath = pickedFile.path;
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String newFileName = '${timestamp}_${processedFiles.length}.jpg';
        final Directory directory = await getTemporaryDirectory();
        final String newPath = '${directory.path}/$newFileName';

        final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          newPath,
          quality: imageQuality,
          format: CompressFormat.jpeg,
          minWidth: maxWidth.toInt(),
          minHeight: maxHeight.toInt(),
        );

        if (compressedFile != null) {
          processedFiles.add(File(compressedFile.path));
        }
      }

      if (processedFiles.isEmpty) return null;
      return processedFiles;
    } catch (e, stackTrace) {
      AppLogger.error('Pick images failed', e, stackTrace);
      if (context.mounted) {
        TopNotification.show(context, message: '選擇圖片失敗，請稍後再試');
      }
      return null;
    }
  }
}
