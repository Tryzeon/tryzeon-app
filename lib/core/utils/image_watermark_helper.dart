import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageWatermarkHelper {
  static Future<Uint8List> addWatermark(
    final Uint8List originalImageBytes, {
    final String text = 'made by Tryzeon',
  }) async {
    // 1. 將 Uint8List 解碼成 ui.Image
    final ui.Codec codec = await ui.instantiateImageCodec(originalImageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // 2. 建立畫布預備繪圖
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // 3. 畫上原始圖片
    canvas.drawImage(image, Offset.zero, ui.Paint());

    // 4. 設定浮水印文字的樣式
    final double fontSize = image.width * 0.04;

    final ui.TextStyle textStyle = ui.TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        ui.Shadow(blurRadius: 4.0, color: Colors.black54, offset: Offset(2.0, 2.0)),
      ],
    );

    final ui.ParagraphStyle paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.right,
    );

    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text);

    final ui.Paragraph paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));

    // 5. 計算浮水印的位置（右下角）
    final double paddingX = image.width * 0.03;
    final double paddingY = image.width * 0.03;

    final ui.Offset offset = ui.Offset(
      -paddingX,
      image.height - paragraph.height - paddingY,
    );

    // 6. 將文字畫上畫布
    canvas.drawParagraph(paragraph, offset);

    // 7. 將結果輸出成新的圖片位元組 (PNG)
    final ui.Picture picture = recorder.endRecording();
    final ui.Image watermarkedImage = await picture.toImage(image.width, image.height);
    final ByteData? byteData = await watermarkedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }
}
