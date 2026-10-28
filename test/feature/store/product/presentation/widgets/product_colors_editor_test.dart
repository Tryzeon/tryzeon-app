import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_color_entry_controller.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_color_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_colors_editor.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

typedef _Harness = ({
  ProductColorManager Function() manager,
  GlobalKey<FormState> formKey,
});

AnalyzeColorPhoto _colours(
  final Map<String, String> colorByPath, {
  final List<String>? calls,
}) => (final image) async {
  calls?.add(image.path);
  return Ok(
    ProductImageAnalysis(
      attributes: ProductAnalysisResult(color: colorByPath[image.path]),
    ),
  );
};

ImageItem _photo(final String path) => ImageItem.newImage(file: File(path));

Future<void> _revealIssues(
  final WidgetTester tester,
  final _Harness harness,
) async {
  harness.manager().revealFirstIssue();
  await tester.pumpAndSettle();
}

Future<_Harness> _pump(
  final WidgetTester tester, {
  final AnalyzeColorPhoto? analyze,
  final ValueChanged<Result<ProductImageAnalysis, Failure>>? onProductAnalysis,
  final List<File>? pickedFiles,
  final double trailingHeight = 0,
}) async {
  late ProductColorManager manager;
  final formKey = GlobalKey<FormState>();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HookBuilder(
              builder: (final _) {
                manager = useProductColorManager(
                  analyze: analyze ?? _colours(const {}),
                  onProductAnalysis: onProductAnalysis,
                );
                return Form(
                  key: formKey,
                  child: Column(
                    children: [
                      ProductColorsEditor(
                        manager: manager,
                        onPickImage: (final _) async => pickedFiles,
                      ),
                      SizedBox(height: trailingHeight),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  return (manager: () => manager, formKey: formKey);
}

Future<void> _addColors(
  final WidgetTester tester,
  final _Harness harness,
  final int count,
) async {
  for (var i = 0; i < count; i++) {
    harness.manager().expand(harness.manager().addColor()!);
    await tester.pumpAndSettle();
  }
}

Future<void> _chooseFromMenu(
  final WidgetTester tester,
  final int index,
  final String action,
) async {
  await tester.ensureVisible(_menuButtons.at(index));
  await tester.tap(_menuButtons.at(index));
  await settle(tester);
  await tester.tap(find.text(action));
  await settle(tester);
}

final _optionalNameField = find.widgetWithText(TextFormField, '顏色名稱（選填）');
final _nameField = find.widgetWithText(TextFormField, '顏色名稱');
final _headers = find.byType(ListTile);
final _dragHandles = find.byIcon(Icons.drag_indicator_rounded);
final _menuButtons = find.byTooltip('更多操作');
final _imageCoachMarks = find.byWidgetPredicate(
  (final w) =>
      w is CoachMarkAnchor && w.target == CoachMarkTarget.productImages,
);

final _addButton = find.ancestor(
  of: find.byIcon(Icons.add_rounded),
  matching: find.byWidgetPredicate((final w) => w is ButtonStyleButton),
);

void main() {
  testWidgets('a single colour shows an optional name and no colour controls', (
    final tester,
  ) async {
    await _pump(tester);

    expect(_optionalNameField, findsOneWidget);
    expect(
      tester.getTopLeft(_optionalNameField).dy,
      greaterThan(tester.getTopLeft(find.text('點擊新增')).dy),
    );
    expect(find.text('照片 0/${AppConstants.maxProductImages}'), findsOneWidget);
    expect(_headers, findsNothing);
    expect(_dragHandles, findsNothing);
    expect(_menuButtons, findsNothing);
    expect(find.textContaining('封面'), findsNothing);
    expect(find.text('新增其他顏色'), findsOneWidget);
  });

  testWidgets(
    'adding a colour starts from its photos and keeps an unnamed first colour '
    'open, now asking for its name',
    (final tester) async {
      final picked = File('new.jpg');
      final harness = await _pump(tester, pickedFiles: [picked]);

      await tester.tap(find.text('新增其他顏色'));
      await tester.pumpAndSettle();

      final [first, second] = harness.manager().entries;
      expect(second.images.value, [ImageItem.newImage(file: picked)]);
      expect(harness.manager().expanded, first);
      expect(harness.manager().isExpanded(second), isFalse);
      expect(_headers, findsNWidgets(2));
      expect(_nameField, findsOneWidget);
      expect(_optionalNameField, findsNothing);
      expect(find.text('未命名顏色'), findsNWidgets(2));
      expect(_dragHandles, findsNWidgets(2));
      expect(_menuButtons, findsNWidgets(2));
      expect(find.text('請輸入顏色名稱'), findsOneWidget);
    },
  );

  testWidgets(
    'adding a colour collapses a finished first colour and opens the new one '
    'below its photos',
    (final tester) async {
      final harness = await _pump(tester, pickedFiles: [File('new.jpg')]);
      harness.manager().entries.single
        ..images.value = [_photo('a.jpg')]
        ..nameController.text = '黑';
      await tester.pump();

      await tester.tap(find.text('新增其他顏色'));
      await tester.pumpAndSettle();

      final [first, second] = harness.manager().entries;
      expect(harness.manager().expanded, second);
      expect(harness.manager().isExpanded(first), isFalse);
      expect(_nameField, findsOneWidget);
      expect(
        tester.getTopLeft(_nameField).dy,
        greaterThan(tester.getTopLeft(find.text('試穿主圖').last).dy),
      );
    },
  );

  testWidgets('the section helper names whose first photo is tried on', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    expect(find.text('第一張照片用於 AI 試穿，請放完整正面照'), findsOneWidget);

    await _addColors(tester, harness, 1);

    expect(find.text('每個顏色的第一張照片用於 AI 試穿，請放完整正面照'), findsOneWidget);
  });

  testWidgets('a single colour sits on the page, colours sit on outlined '
      'cards', (final tester) async {
    final harness = await _pump(tester);
    BorderSide? sideOf(final Card card) =>
        (card.shape as RoundedRectangleBorder?)?.side;
    expect(sideOf(tester.widget<Card>(find.byType(Card))), BorderSide.none);

    await _addColors(tester, harness, 1);

    expect(
      tester.widgetList<Card>(find.byType(Card)).map(sideOf),
      everyElement(isNull),
    );
  });

  testWidgets('a lone colour keeps its shown errors when a colour joins', (
    final tester,
  ) async {
    final harness = await _pump(tester, pickedFiles: [File('new.jpg')]);
    harness.formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('請為這個顏色選擇至少一張照片'), findsOneWidget);

    await tester.tap(find.text('新增其他顏色'));
    await tester.pumpAndSettle();

    expect(find.text('請為這個顏色選擇至少一張照片'), findsOneWidget);
  });

  testWidgets('an open colour with issues is outlined in error after saving', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);
    final colorScheme = AppTheme.lightTheme.colorScheme;
    Color? openBorder() =>
        (tester
                    .widget<Card>(
                      find.ancestor(
                        of: _nameField,
                        matching: find.byType(Card),
                      ),
                    )
                    .shape
                as RoundedRectangleBorder?)
            ?.side
            .color;

    expect(openBorder(), isNull);

    await _revealIssues(tester, harness);

    expect(openBorder(), colorScheme.error);
  });

  testWidgets('an open colour cannot be dragged by its handle', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);

    final listeners = tester
        .widgetList<ReorderableDragStartListener>(
          find.byType(ReorderableDragStartListener),
        )
        .toList();
    expect(listeners.map((final l) => l.enabled), [true, false]);
  });

  testWidgets('deleting a colour waits for confirmation', (final tester) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);
    harness.manager().entries.last.nameController.text = '霧灰';
    await tester.pump();

    await _chooseFromMenu(tester, 1, '刪除顏色');
    expect(find.text('刪除「霧灰」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(harness.manager().entries, hasLength(2));
  });

  group('the name helper', () {
    testWidgets('marks an AI-suggested name until the store changes it', (
      final tester,
    ) async {
      final harness = await _pump(tester, analyze: _colours({'a.jpg': '霧灰'}));
      harness.manager().entries.single.images.value = [_photo('a.jpg')];
      await tester.pump();
      await tester.pump();

      expect(find.text('AI 依照片建議，可直接修改'), findsOneWidget);

      await tester.enterText(_optionalNameField, '灰');
      await tester.pump();

      expect(find.text('AI 依照片建議，可直接修改'), findsNothing);
    });

    testWidgets('asks for a name the photo could not tell', (
      final tester,
    ) async {
      final harness = await _pump(
        tester,
        analyze: (final _) async => const Err(ServerFailure()),
      );
      harness.manager().entries.single.images.value = [_photo('a.jpg')];
      await tester.pump();
      await tester.pump();

      expect(find.text('AI 未能判斷顏色，請手動輸入'), findsOneWidget);

      await tester.enterText(_optionalNameField, '黑');
      await tester.pump();

      expect(find.text('AI 未能判斷顏色，請手動輸入'), findsNothing);
    });
  });

  testWidgets('cancelling the photo picker adds no colour', (
    final tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(find.text('新增其他顏色'));
    await tester.pump();

    expect(harness.manager().entries, hasLength(1));
  });

  testWidgets(
    'tapping a collapsed colour opens it and collapses the open one',
    (final tester) async {
      final harness = await _pump(tester);
      await _addColors(tester, harness, 1);
      final [first, second] = harness.manager().entries;

      await tester.tap(find.text('未命名顏色').first);
      await tester.pumpAndSettle();

      expect(harness.manager().expanded, first);
      expect(harness.manager().isExpanded(second), isFalse);
      expect(_nameField, findsOneWidget);
    },
  );

  testWidgets('opening a colour scrolls the whole colour into view', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 7);
    harness.manager().collapse();
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(Scaffold));
    final lowestVisibleRow = _headers.evaluate().lastWhere(
      (final row) =>
          tester
              .getRect(find.byElementPredicate((final e) => e == row))
              .bottom <=
          viewport.bottom,
    );

    await tester.tap(
      find.byElementPredicate((final e) => e == lowestVisibleRow),
    );
    await tester.pumpAndSettle();

    final openCard = find.ancestor(of: _nameField, matching: find.byType(Card));
    expect(tester.getRect(openCard).bottom, lessThanOrEqualTo(viewport.bottom));
    expect(tester.getRect(openCard).top, greaterThanOrEqualTo(viewport.top));
  });

  testWidgets('tapping the open colour header collapses it', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);

    await tester.tap(_headers.last);
    await tester.pumpAndSettle();

    expect(harness.manager().expanded, isNull);
    expect(_headers, findsNWidgets(2));
    expect(_nameField, findsNothing);
  });

  testWidgets(
    'a collapsed colour shows all its issues, neutral until the store saves',
    (final tester) async {
      final harness = await _pump(tester);
      await _addColors(tester, harness, 1);
      final [first, second] = harness.manager().entries;
      Color? borderOf(final String text) {
        final card = tester.widget<Card>(
          find.ancestor(of: find.text(text), matching: find.byType(Card)),
        );
        return (card.shape as RoundedRectangleBorder?)?.side.color;
      }

      Color? textColorOf(final String text) =>
          tester.widget<Text>(find.text(text)).style?.color;

      const missingBoth = '還沒有照片 · 請輸入顏色名稱';
      final colorScheme = AppTheme.lightTheme.colorScheme;
      expect(find.text(missingBoth), findsOneWidget);
      expect(borderOf(missingBoth), isNull);
      expect(textColorOf(missingBoth), isNot(colorScheme.error));

      await _revealIssues(tester, harness);
      harness.manager().collapse();
      await tester.pumpAndSettle();
      expect(find.text(missingBoth), findsNWidgets(2));
      expect(
        tester
            .widgetList<Card>(find.byType(Card))
            .map((final c) => (c.shape as RoundedRectangleBorder?)?.side.color),
        everyElement(colorScheme.error),
      );
      expect(
        tester
            .widgetList<Text>(find.text(missingBoth))
            .map((final t) => t.style?.color),
        everyElement(colorScheme.error),
      );

      first.images.value = [_photo('a.jpg')];
      await tester.pump();
      await tester.pump();
      expect(find.text('請輸入顏色名稱'), findsOneWidget);

      first.nameController.text = '黑';
      await tester.pump();
      expect(
        find.text('照片 1/${AppConstants.maxProductImages}'),
        findsOneWidget,
      );
      expect(borderOf('黑'), isNull);

      harness.manager().expand(second);
      await tester.pumpAndSettle();
      await tester.enterText(_nameField, '黑 ');
      await tester.pump();
      expect(find.text('顏色名稱重複'), findsNWidgets(2));
    },
  );

  testWidgets(
    'saving reveals the first colour with an issue and validates its fields',
    (final tester) async {
      final harness = await _pump(tester);
      await _addColors(tester, harness, 1);
      final first = harness.manager().entries.first;

      expect(harness.manager().revealFirstIssue(), isTrue);
      await tester.pumpAndSettle();

      expect(harness.manager().expanded, first);
      expect(find.text('請輸入顏色名稱'), findsOneWidget);
      expect(find.text('請為這個顏色選擇至少一張照片'), findsOneWidget);
    },
  );

  testWidgets('a lone colour with too many photos says so under them', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    harness.manager().entries.single.images.value = [
      for (var i = 0; i <= AppConstants.maxProductImages; i++) _photo('$i.jpg'),
    ];
    await tester.pump();

    expect(harness.manager().revealFirstIssue(), isTrue);
    await tester.pumpAndSettle();

    expect(
      find.text('照片最多 ${AppConstants.maxProductImages} 張'),
      findsOneWidget,
    );
  });

  testWidgets('an open colour with an issue is revealed in place', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    harness.manager().entries.single
      ..images.value = [_photo('a.jpg')]
      ..nameController.text = '黑';
    await _addColors(tester, harness, 1);

    final second = harness.manager().entries.last;

    expect(harness.manager().revealFirstIssue(), isTrue);
    await tester.pumpAndSettle();
    expect(harness.manager().showsIssues, isTrue);
    expect(harness.manager().expanded, second);
    expect(find.text('請為這個顏色選擇至少一張照片'), findsOneWidget);
  });

  testWidgets('the opened colour stays on screen while the one above it '
      'closes', (final tester) async {
    final harness = await _pump(tester, trailingHeight: 1200);
    harness.manager().entries.single
      ..nameController.text = '黑'
      ..images.value = [_photo('black.jpg')];
    for (final name in ['白', '紅', '藍']) {
      harness
              .manager()
              .addColor(images: [_photo('$name.jpg')])!
              .nameController
              .text =
          name;
      await tester.pumpAndSettle();
    }
    harness.manager().addColor();
    await tester.pumpAndSettle();
    harness.manager().expand(harness.manager().entries.first);
    await tester.pumpAndSettle();

    expect(harness.manager().revealFirstIssue(), isTrue);
    await tester.pumpAndSettle();

    final error = tester.getRect(find.text('請為這個顏色選擇至少一張照片'));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(error.top, greaterThanOrEqualTo(0));
    expect(error.bottom, lessThanOrEqualTo(screen.height));
  });

  testWidgets('deleting from the menu back to one colour restores the single '
      'layout', (final tester) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);

    await _chooseFromMenu(tester, 1, '刪除顏色');
    expect(find.text('刪除這個顏色？'), findsOneWidget);
    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();

    expect(harness.manager().entries, hasLength(1));
    expect(_optionalNameField, findsOneWidget);
    expect(_menuButtons, findsNothing);
  });

  testWidgets('設為封面 in the menu moves the colour first', (final tester) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 2);
    final names = ['黑', '白', '霧灰'];
    for (final (index, entry) in harness.manager().entries.indexed) {
      entry.nameController.text = names[index];
    }
    await tester.pump();

    await _chooseFromMenu(tester, 2, '設為封面');

    expect(harness.manager().entries.map((final e) => e.nameController.text), [
      '霧灰',
      '黑',
      '白',
    ]);
  });

  testWidgets(
    'only the cover colour is tagged 封面; every first photo is the try-on '
    'photo',
    (final tester) async {
      final harness = await _pump(tester);
      await _addColors(tester, harness, 1);
      final [first, second] = harness.manager().entries;
      first.images.value = [_photo('a.jpg')];
      second.images.value = [_photo('b.jpg')];
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(of: _headers.first, matching: find.text('封面')),
        findsOneWidget,
      );
      expect(find.text('封面'), findsOneWidget);
      expect(find.text('試穿主圖'), findsOneWidget);

      await tester.tap(_headers.first);
      await tester.pumpAndSettle();

      expect(find.text('封面'), findsOneWidget);
      expect(find.text('試穿主圖'), findsOneWidget);
    },
  );

  testWidgets('the cover colour has no 設為封面 in its menu', (final tester) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);

    await tester.tap(_menuButtons.first);
    await settle(tester);

    expect(find.text('設為封面'), findsNothing);
    expect(find.text('刪除顏色'), findsOneWidget);
  });

  testWidgets('the add button is disabled and names the limit at ten colours', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    await _addColors(tester, harness, 1);
    expect(find.text('新增顏色'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(_addButton).enabled, isTrue);

    await _addColors(tester, harness, AppConstants.maxProductColors - 2);

    expect(harness.manager().entries, hasLength(AppConstants.maxProductColors));
    expect(tester.widget<ButtonStyleButton>(_addButton).enabled, isFalse);
    expect(
      find.text('最多 ${AppConstants.maxProductColors} 個顏色'),
      findsOneWidget,
    );
  });

  testWidgets('the cover colour anchors the image coach mark, open or not', (
    final tester,
  ) async {
    final harness = await _pump(tester);
    expect(_imageCoachMarks, findsOneWidget);

    await _addColors(tester, harness, 1);
    expect(_imageCoachMarks, findsOneWidget);
    expect(
      find.descendant(of: _headers.first, matching: _imageCoachMarks),
      findsOneWidget,
    );

    await tester.tap(_headers.first);
    await tester.pumpAndSettle();
    expect(_imageCoachMarks, findsOneWidget);
    expect(
      find.descendant(of: _headers, matching: _imageCoachMarks),
      findsNothing,
    );
  });

  testWidgets(
    'an analysed colour fills an empty name, even when collapsed, but not a '
    'typed one',
    (final tester) async {
      final harness = await _pump(
        tester,
        analyze: _colours({'first.jpg': '霧灰', 'second.jpg': '霧灰'}),
      );
      await _addColors(tester, harness, 1);
      await tester.enterText(_nameField, '白');

      final [first, second] = harness.manager().entries;
      first.images.value = [_photo('first.jpg')];
      second.images.value = [_photo('second.jpg')];
      await tester.pump();
      await tester.pump();

      expect(first.nameController.text, '霧灰');
      expect(find.text('霧灰'), findsOneWidget);
      expect(second.nameController.text, '白');
    },
  );

  testWidgets('each colour shows AI 分析中… while its photo is analysed', (
    final tester,
  ) async {
    final pending =
        <String, Completer<Result<ProductImageAnalysis, Failure>>>{};
    final harness = await _pump(
      tester,
      analyze: (final image) => (pending[image.path] = Completer()).future,
    );
    await _addColors(tester, harness, 1);
    final [first, second] = harness.manager().entries;

    first.images.value = [_photo('first.jpg')];
    second.images.value = [_photo('second.jpg')];
    await tester.pump();

    expect(find.text('AI 分析中…'), findsNWidgets(2));
    expect(
      find.descendant(of: _headers, matching: find.text('AI 分析中…')),
      findsNWidgets(2),
    );

    pending['first.jpg']!.complete(
      const Ok(ProductImageAnalysis(attributes: ProductAnalysisResult())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('AI 分析中…'), findsOneWidget);
    expect(find.text('請輸入顏色名稱'), findsOneWidget);
  });

  testWidgets('a named cover is still analysed to pre-fill the product', (
    final tester,
  ) async {
    final pending = Completer<Result<ProductImageAnalysis, Failure>>();
    final reported = <Result<ProductImageAnalysis, Failure>>[];
    final harness = await _pump(
      tester,
      analyze: (final _) => pending.future,
      onProductAnalysis: reported.add,
    );
    final entry = harness.manager().entries.single;

    entry.nameController.text = '黑';
    entry.images.value = [_photo('cover.jpg')];
    await tester.pump();

    expect(find.text('AI 分析中…'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (final w) =>
            w is CoachMarkAnchor &&
            w.target == CoachMarkTarget.productImageAnalyzing,
      ),
      findsOneWidget,
    );

    pending.complete(
      const Ok(
        ProductImageAnalysis(attributes: ProductAnalysisResult(color: '霧灰')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(reported, hasLength(1));
    expect(reported.single.isSuccess, isTrue);
    expect(entry.nameController.text, '黑');
    expect(find.text('AI 分析中…'), findsNothing);
  });

  testWidgets('a named colour whose first image is new is not analysed', (
    final tester,
  ) async {
    final analysedPaths = <String>[];
    final harness = await _pump(
      tester,
      analyze: _colours({'cover.jpg': '霧灰'}, calls: analysedPaths),
    );

    final entry = harness.manager().entries.single;
    entry.nameController.text = '黑';
    entry.images.value = [_photo('cover.jpg')];
    await tester.pump();
    await tester.pump();

    expect(analysedPaths, isEmpty);
    expect(entry.nameController.text, '黑');
  });

  testWidgets('a colour name keeps at most $maxColorNameLength characters', (
    final tester,
  ) async {
    final harness = await _pump(tester);

    await tester.enterText(_optionalNameField, 'a' * 25);
    await tester.pump();

    expect(
      harness.manager().entries.single.nameController.text,
      'a' * maxColorNameLength,
    );
    expect(find.text('$maxColorNameLength/$maxColorNameLength'), findsNothing);
  });

  group('the AI-suggested name', () {
    Future<void> setMainImage(
      final WidgetTester tester,
      final ProductColorEntryController entry,
      final String path,
    ) async {
      entry.images.value = [];
      entry.images.value = [ImageItem.newImage(file: File(path))];
      await tester.pump();
      await tester.pump();
    }

    testWidgets('follows a new set of photos', (final tester) async {
      final harness = await _pump(
        tester,
        analyze: _colours({'a.jpg': '白色', 'b.jpg': '黑色'}),
      );
      final entry = harness.manager().entries.single;

      await setMainImage(tester, entry, 'a.jpg');
      expect(entry.nameController.text, '白色');

      await setMainImage(tester, entry, 'b.jpg');
      expect(entry.nameController.text, '黑色');
    });

    testWidgets('never replaces a name the store typed', (final tester) async {
      final harness = await _pump(
        tester,
        analyze: _colours({'a.jpg': '白色', 'b.jpg': '黑色'}),
      );
      await _addColors(tester, harness, 1);
      final entry = harness.manager().entries.first;

      await setMainImage(tester, entry, 'a.jpg');
      expect(entry.nameController.text, '白色');
      await tester.tap(_headers.first);
      await tester.pumpAndSettle();
      await tester.enterText(_nameField, '霧灰');

      await setMainImage(tester, entry, 'b.jpg');
      expect(entry.nameController.text, '霧灰');
    });
  });
}
