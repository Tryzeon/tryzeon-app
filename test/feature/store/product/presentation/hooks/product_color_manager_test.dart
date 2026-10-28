import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_color_entry_controller.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_color_manager.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/product_color_fixtures.dart';

Future<ProductColorManager Function()> _pump(
  final WidgetTester tester, {
  final List<ProductColor>? initialColors,
  final AnalyzeColorPhoto? analyze,
  final ValueChanged<Result<ProductImageAnalysis, Failure>>? onProductAnalysis,
}) async {
  late ProductColorManager manager;
  await tester.pumpWidget(
    HookBuilder(
      builder: (final _) {
        manager = useProductColorManager(
          analyze: analyze ?? _recording([]),
          onProductAnalysis: onProductAnalysis,
          initialColors: initialColors,
        );
        return const SizedBox();
      },
    ),
  );
  return () => manager;
}

AnalyzeColorPhoto _recording(
  final List<String> calls, {
  final String? color,
  final Failure? failure,
}) => (final image) async {
  calls.add(image.path);
  if (failure != null) return Err(failure);
  return Ok(
    ProductImageAnalysis(attributes: ProductAnalysisResult(color: color)),
  );
};

ImageItem _photo(final String path) => ImageItem.newImage(file: File(path));

Future<void> _settle(final WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  group('analysis', () {
    testWidgets('runs once when a colour first gets photos, not when its '
        'photos or the colours are reordered', (final tester) async {
      final calls = <String>[];
      final manager = await _pump(tester, analyze: _recording(calls));
      final first = manager().entries.single;

      first.images.value = [_photo('a.jpg'), _photo('b.jpg')];
      await _settle(tester);
      first.images.value = [_photo('b.jpg'), _photo('a.jpg')];
      first.images.value = [...first.images.value, _photo('c.jpg')];
      first.images.value = first.images.value.sublist(1);
      manager().addColor(images: [_photo('d.jpg')]);
      await _settle(tester);
      manager().reorder(1, 0);
      await _settle(tester);

      expect(calls, ['a.jpg', 'd.jpg']);
    });

    testWidgets('runs again once a colour loses all its photos and gets new '
        'ones', (final tester) async {
      final calls = <String>[];
      final manager = await _pump(
        tester,
        analyze: _recording(calls, color: '白色'),
      );
      final entry = manager().entries.single;

      entry.images.value = [_photo('a.jpg')];
      await _settle(tester);
      entry.images.value = [];
      expect(entry.nameSuggestion.value, ColorNameSuggestion.none);
      entry.images.value = [_photo('b.jpg')];
      await _settle(tester);

      expect(calls, ['a.jpg', 'b.jpg']);
    });

    testWidgets('skips a named colour and never the colours being edited', (
      final tester,
    ) async {
      final calls = <String>[];
      final manager = await _pump(
        tester,
        analyze: _recording(calls),
        initialColors: [
          productColorFixture(imagePaths: const ['a.jpg']),
        ],
      );
      final existing = manager().entries.single;

      existing.images.value = [_photo('new.jpg'), ...existing.images.value];
      existing.nameController.clear();
      existing.images.value = existing.images.value.reversed.toList();
      final named = manager().addColor()!..nameController.text = '黑';
      named.images.value = [_photo('named.jpg')];
      await _settle(tester);

      expect(calls, isEmpty);
    });

    testWidgets('drops a result for photos the colour no longer has', (
      final tester,
    ) async {
      final pending = Completer<Result<ProductImageAnalysis, Failure>>();
      final reported = <Result<ProductImageAnalysis, Failure>>[];
      final manager = await _pump(
        tester,
        analyze: (final _) => pending.future,
        onProductAnalysis: reported.add,
      );
      final entry = manager().entries.single;

      entry.images.value = [_photo('a.jpg')];
      entry.images.value = [];
      pending.complete(
        const Ok(
          ProductImageAnalysis(attributes: ProductAnalysisResult(color: '白色')),
        ),
      );
      await _settle(tester);

      expect(entry.nameController.text, isEmpty);
      expect(entry.nameSuggestion.value, ColorNameSuggestion.none);
      expect(reported, isEmpty);
    });

    testWidgets('fills the product from a colour analysed alongside one that '
        'fails', (final tester) async {
      final pending =
          <String, Completer<Result<ProductImageAnalysis, Failure>>>{};
      final reported = <Result<ProductImageAnalysis, Failure>>[];
      final manager = await _pump(
        tester,
        analyze: (final image) => (pending[image.path] = Completer()).future,
        onProductAnalysis: reported.add,
      );

      manager().entries.single.images.value = [_photo('a.jpg')];
      manager().addColor(images: [_photo('b.jpg')]);
      await tester.pump();
      pending['a.jpg']!.complete(const Err(ServerFailure()));
      await _settle(tester);
      pending['b.jpg']!.complete(
        const Ok(ProductImageAnalysis(attributes: ProductAnalysisResult())),
      );
      await _settle(tester);

      expect(reported.map((final r) => r.isSuccess), [false, true]);
    });

    testWidgets('pre-fills the product once, from the first analysis, even for '
        'a named colour', (final tester) async {
      final calls = <String>[];
      final reported = <Result<ProductImageAnalysis, Failure>>[];
      final manager = await _pump(
        tester,
        analyze: _recording(calls),
        onProductAnalysis: reported.add,
      );
      final cover = manager().entries.single..nameController.text = '黑';

      cover.images.value = [_photo('cover.jpg')];
      await _settle(tester);
      final second = manager().addColor()!..nameController.text = '白';
      second.images.value = [_photo('second.jpg')];
      manager().reorder(1, 0);
      await _settle(tester);

      expect(calls, ['cover.jpg']);
      expect(reported, hasLength(1));
      expect(reported.single.isSuccess, isTrue);
    });

    testWidgets('lets the next colour pre-fill the product after a failure', (
      final tester,
    ) async {
      final calls = <String>[];
      var failure = true;
      final reported = <Result<ProductImageAnalysis, Failure>>[];
      final manager = await _pump(
        tester,
        analyze: (final image) async {
          calls.add(image.path);
          return failure
              ? const Err(ServerFailure())
              : const Ok(
                  ProductImageAnalysis(attributes: ProductAnalysisResult()),
                );
        },
        onProductAnalysis: reported.add,
      );
      final cover = manager().entries.single..nameController.text = '黑';

      cover.images.value = [_photo('cover.jpg')];
      await _settle(tester);
      failure = false;
      final second = manager().addColor()!..nameController.text = '白';
      second.images.value = [_photo('second.jpg')];
      await _settle(tester);

      expect(calls, ['cover.jpg', 'second.jpg']);
      expect(reported.map((final r) => r.isSuccess), [false, true]);
    });
    testWidgets('marks the name unavailable when no colour is recognised', (
      final tester,
    ) async {
      final manager = await _pump(
        tester,
        analyze: (final image) async => image.path == 'fails.jpg'
            ? const Err(ServerFailure())
            : const Ok(
                ProductImageAnalysis(attributes: ProductAnalysisResult()),
              ),
      );
      final failed = manager().entries.single;
      final unrecognised = manager().addColor()!;

      failed.images.value = [_photo('fails.jpg')];
      unrecognised.images.value = [_photo('plain.jpg')];
      expect(failed.nameSuggestion.value, ColorNameSuggestion.pending);
      await _settle(tester);

      expect(failed.nameSuggestion.value, ColorNameSuggestion.unavailable);
      expect(
        unrecognised.nameSuggestion.value,
        ColorNameSuggestion.unavailable,
      );
    });

    testWidgets('a recognised colour leaves no unavailable mark', (
      final tester,
    ) async {
      final manager = await _pump(tester, analyze: _recording([], color: '白色'));
      final entry = manager().entries.single;

      entry.images.value = [_photo('a.jpg')];
      await _settle(tester);

      expect(entry.nameController.text, '白色');
      expect(entry.nameSuggestion.value, ColorNameSuggestion.none);
    });
  });

  testWidgets('starts with one empty colour when there is nothing to edit', (
    final tester,
  ) async {
    final manager = await _pump(tester);

    expect(manager().entries, hasLength(1));
    expect(manager().entries.single.id, isNull);
    expect(manager().entries.single.images.value, isEmpty);
  });

  testWidgets('seeds one entry per existing colour in order', (
    final tester,
  ) async {
    final manager = await _pump(
      tester,
      initialColors: [
        productColorFixture(imagePaths: const ['a.jpg', 'b.jpg']),
        productColorFixture(imagePaths: const ['c.jpg'], position: 1),
      ],
    );

    expect(manager().entries.map((final e) => e.id), [
      'color-p1-0',
      'color-p1-1',
    ]);
    expect(manager().entries.first.images.value, const [
      ImageItem.existing(path: 'a.jpg', url: 'https://x/a.jpg'),
      ImageItem.existing(path: 'b.jpg', url: 'https://x/b.jpg'),
    ]);
  });

  testWidgets('addColor stops at ten colours', (final tester) async {
    final manager = await _pump(tester);

    for (var i = 0; i < 12; i++) {
      manager().addColor();
      await tester.pump();
    }

    expect(manager().entries, hasLength(10));
    expect(manager().canAddColor, isFalse);
  });

  testWidgets('reorder moves an entry and toColorItems follows the new order', (
    final tester,
  ) async {
    final manager = await _pump(
      tester,
      initialColors: [
        productColorFixture(imagePaths: const ['a.jpg']),
        productColorFixture(imagePaths: const ['b.jpg'], position: 1),
        productColorFixture(imagePaths: const ['c.jpg'], position: 2),
      ],
    );

    manager().reorder(2, 0);
    await tester.pump();

    expect(
      manager().toColorItems().map((final c) => (c as ExistingColorItem).id),
      ['color-p1-2', 'color-p1-0', 'color-p1-1'],
    );
  });

  testWidgets('removing a colour disposes its controller after the frame', (
    final tester,
  ) async {
    final manager = await _pump(
      tester,
      initialColors: [
        productColorFixture(imagePaths: const ['a.jpg']),
        productColorFixture(imagePaths: const ['b.jpg'], position: 1),
      ],
    );
    final removed = manager().entries.first;

    manager().removeColor(removed);
    expect(() => removed.nameController.addListener(() {}), returnsNormally);
    await tester.pump();

    expect(manager().entries, hasLength(1));
    expect(() => removed.nameController.addListener(() {}), throwsFlutterError);
  });

  testWidgets(
    'a lone unnamed colour has no name issue; adding a second makes both missing',
    (final tester) async {
      final manager = await _pump(tester);

      expect(manager().nameIssueOf(manager().entries.single), isNull);

      manager().addColor();
      await tester.pump();

      expect(
        manager().entries.map(manager().nameIssueOf),
        everyElement(ColorIssue.missingName),
      );
    },
  );

  testWidgets('a colour lists every issue it has', (final tester) async {
    final manager = await _pump(tester);
    manager().addColor();
    await tester.pump();

    expect(manager().issuesOf(manager().entries.first), [
      ColorIssue.missingImages,
      ColorIssue.missingName,
    ]);
  });

  testWidgets('addColor seeds the new colour with its photos', (
    final tester,
  ) async {
    final manager = await _pump(tester);
    final image = ImageItem.newImage(file: File('/tmp/new.jpg'));

    manager().addColor(images: [image]);
    await tester.pump();

    expect(manager().entries.last.images.value, [image]);
  });

  testWidgets('toNewColorItems carries the picked files', (final tester) async {
    final manager = await _pump(
      tester,
      initialColors: [
        productColorFixture(imagePaths: const ['a.jpg']),
      ],
    );
    manager().addColor();
    await tester.pump();
    final file = File('/tmp/new.jpg');
    manager().entries.last.images.value = [ImageItem.newImage(file: file)];

    final items = manager().toNewColorItems();

    expect(items, hasLength(1));
    expect(items.single.images, [file]);
    expect(manager().mainNewImagePath, isNull);
  });

  testWidgets('starts with every edited colour collapsed and opens each '
      'added one', (final tester) async {
    final manager = await _pump(
      tester,
      initialColors: [
        productColorFixture(imagePaths: const ['a.jpg']),
        productColorFixture(imagePaths: const ['b.jpg'], position: 1),
      ],
    );
    expect(manager().expanded, isNull);
    expect(manager().entries.where(manager().isExpanded), isEmpty);

    manager().addColor();
    await tester.pump();

    expect(manager().expanded, manager().entries.last);
    expect(manager().isExpanded(manager().entries.first), isFalse);
  });

  testWidgets('keeps an unfinished open colour open when adding another', (
    final tester,
  ) async {
    final manager = await _pump(tester);
    final lone = manager().entries.single..images.value = [_photo('a.jpg')];

    manager().addColor(images: [_photo('b.jpg')]);
    await tester.pump();
    expect(manager().expanded, lone);

    lone.nameController.text = '黑';
    manager().addColor(images: [_photo('c.jpg')]);
    await tester.pump();
    expect(manager().expanded, manager().entries.last);
  });

  testWidgets('removing the open colour leaves every colour collapsed', (
    final tester,
  ) async {
    final manager = await _pump(tester);
    manager().addColor();
    manager().addColor();
    await tester.pump();

    manager().removeColor(manager().expanded!);
    await tester.pump();

    expect(manager().expanded, isNull);
    expect(manager().entries.where(manager().isExpanded), isEmpty);
  });

  testWidgets('a lone colour always counts as open', (final tester) async {
    final manager = await _pump(tester);
    manager().addColor();
    await tester.pump();

    manager().removeColor(manager().expanded!);
    await tester.pump();

    expect(manager().expanded, isNull);
    expect(manager().isExpanded(manager().entries.single), isTrue);
  });
}
