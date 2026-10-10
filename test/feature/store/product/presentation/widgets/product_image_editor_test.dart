import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_image_editor.dart';

// Semantics off: ReorderableListView with Image.file children trips a
// `_needsLayout` semantics assertion under flutter_test.
void main() {
  Future<void> pumpEditor(
    final WidgetTester tester,
    final List<ImageItem> images,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProductImageEditor(
            images: images,
            onImagesChanged: (final _) {},
            onPickImage: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('only the first image is badged as the main image', (
    final tester,
  ) async {
    await pumpEditor(tester, [
      ImageItem.newImage(file: File('a.jpg')),
      ImageItem.newImage(file: File('b.jpg')),
    ]);

    expect(find.text('主圖'), findsOneWidget);
  }, semanticsEnabled: false);

  testWidgets('no badge before any image is picked', (final tester) async {
    await pumpEditor(tester, const []);

    expect(find.text('主圖'), findsNothing);
  }, semanticsEnabled: false);
}
