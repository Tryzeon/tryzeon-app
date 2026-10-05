import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/analyze_wardrobe_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/sheets/upload_wardrobe_item_sheet.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeAnalyze implements AnalyzeWardrobeImage {
  final labelsResult = Completer<LabelResult>();

  @override
  Future<LabelResult> labels(final File image) => labelsResult.future;

  @override
  Future<Uint8List?> removeBackground(final File image) async => null;
}

class _FakeEdit extends WardrobeEditNotifier {
  final uploadResult = Completer<Result<void, Failure>>();
  final uploadedTypes = <GarmentType>[];

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<Result<void, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
    required final List<String> tags,
    final Uint8List? replacementBytes,
  }) async {
    final link = ref.keepAlive();
    uploadedTypes.add(garmentType);
    state = const AsyncLoading();
    final result = await uploadResult.future;
    state = const AsyncData(null);
    link.close();
    return result;
  }
}

void main() {
  late _FakeAnalyze analyze;
  late _FakeEdit edit;

  Future<({Future<GarmentType?> result})> open(final WidgetTester tester) {
    // Built inside the test so their completers resolve in its fake-async zone.
    analyze = _FakeAnalyze();
    edit = _FakeEdit();
    return openSheet<GarmentType>(
      tester,
      (final context) => UploadWardrobeItemSheet.show(
        context: context,
        image: File('missing.jpg'),
      ),
      overrides: [
        analyzeWardrobeImageUseCaseProvider.overrideWithValue(analyze),
        wardrobeEditProvider.overrideWith(() => edit),
        wardrobeCapacityProvider.overrideWith(
          (final ref) async => const WardrobeCapacity(used: 1, limit: 10),
        ),
      ],
    );
  }

  Finder uploadButton() => find.widgetWithText(FilledButton, '上傳');

  Future<void> pickPantsAndUpload(final WidgetTester tester) async {
    await tester.tap(find.text(GarmentType.pants.displayName));
    await settle(tester);
    await tester.tap(uploadButton());
    await tester.pump();
  }

  Future<void> drainToasts(final WidgetTester tester) async {
    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  }

  testWidgets('needs a garment type before uploading', (final tester) async {
    await open(tester);

    expect(tester.widget<FilledButton>(uploadButton()).onPressed, isNull);
  });

  testWidgets('uploads while tags are still being analyzed', (
    final tester,
  ) async {
    final sheet = await open(tester);

    expect(find.text('分析中…'), findsOneWidget);

    await pickPantsAndUpload(tester);
    edit.uploadResult.complete(const Ok(null));
    await settle(tester);

    expect(edit.uploadedTypes, [GarmentType.pants]);
    expect(find.byType(UploadWardrobeItemSheet), findsNothing);
    expect(await sheet.result, GarmentType.pants);
  });

  testWidgets('picks the analyzed garment type for the user', (
    final tester,
  ) async {
    await open(tester);

    analyze.labelsResult.complete(
      const LabelResult(tags: ['denim'], garmentType: GarmentType.skirt),
    );
    await settle(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, GarmentType.skirt.displayName),
    );
    expect(chip.selected, isTrue);
    expect(find.text('#denim'), findsOneWidget);
  });

  testWidgets('keeps the sheet open with an error when the upload fails', (
    final tester,
  ) async {
    await open(tester);

    await pickPantsAndUpload(tester);
    edit.uploadResult.complete(const Err(NetworkFailure()));
    await settle(tester);

    expect(find.byType(UploadWardrobeItemSheet), findsOneWidget);
    expect(find.text('無網路連線，請檢查您的網路設定'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('still reports a failure after the sheet is dragged away', (
    final tester,
  ) async {
    await open(tester);

    await pickPantsAndUpload(tester);
    await dismissByDrag(tester);
    expect(find.byType(UploadWardrobeItemSheet), findsNothing);

    edit.uploadResult.complete(const Err(NetworkFailure()));
    await settle(tester);

    expect(find.text('無網路連線，請檢查您的網路設定'), findsOneWidget);
    await drainToasts(tester);
  });

  testWidgets('still shows the full-wardrobe dialog after a drag dismiss', (
    final tester,
  ) async {
    await open(tester);

    await pickPantsAndUpload(tester);
    await dismissByDrag(tester);
    edit.uploadResult.complete(const Err(ValidationFailure()));
    await settle(tester);

    expect(find.text('衣櫃已達上限'), findsOneWidget);
  });
}
