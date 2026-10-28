import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_color_entry_controller.dart';
import 'package:typed_result/typed_result.dart';

/// Asks one colour's block to scroll into view once every open or close
/// animation has settled. Each request is a new object, so asking again for
/// the same colour reveals it again.
class ColorRevealRequest {
  ColorRevealRequest(this.entry);

  final ProductColorEntryController entry;
}

class ProductColorManager {
  ProductColorManager({
    required this.entries,
    required this.addColor,
    required this.removeColor,
    required this.reorder,
    required this.expanded,
    required this.revealRequest,
    required this.expand,
    required this.collapse,
    required this.showsIssues,
    required final void Function() showIssues,
  }) : _showIssues = showIssues;

  final List<ProductColorEntryController> entries;
  final ProductColorEntryController? expanded;
  final ColorRevealRequest? revealRequest;

  final ProductColorEntryController? Function({List<ImageItem> images})
  addColor;
  final void Function(ProductColorEntryController entry) removeColor;
  final void Function(int oldIndex, int newIndex) reorder;
  final void Function(ProductColorEntryController entry) expand;
  final void Function() collapse;

  final bool showsIssues;
  final void Function() _showIssues;

  bool get isSingle => entries.length == 1;

  bool isExpanded(final ProductColorEntryController entry) =>
      isSingle || entry == expanded;

  bool get canAddColor => entries.length < AppConstants.maxProductColors;

  List<ColorItem> toColorItems() =>
      entries.map((final entry) => entry.toColorItem()).toList();

  List<NewColorItem> toNewColorItems() =>
      toColorItems().whereType<NewColorItem>().toList();

  List<ColorIssue> issuesOf(final ProductColorEntryController entry) =>
      _issuesAmong(entry, entries);

  ColorIssue? nameIssueOf(final ProductColorEntryController entry) =>
      issuesOf(entry).where((final issue) => issue.concernsName).firstOrNull;

  ColorIssue? photoIssueOf(final ProductColorEntryController entry) =>
      issuesOf(entry).where((final issue) => !issue.concernsName).firstOrNull;

  /// Issues stay neutral until the store first saves. A collapsed colour has
  /// no mounted fields for the form to validate, so the first colour with an
  /// issue is opened and revealed: its fields validate as they mount.
  /// Returns whether any colour has an issue.
  bool revealFirstIssue() {
    final firstIssue = entries
        .where((final entry) => issuesOf(entry).isNotEmpty)
        .firstOrNull;
    if (firstIssue == null) return false;
    _showIssues();
    expand(firstIssue);
    return true;
  }

  ProductColorEntryController get cover => entries.first;

  String? get mainNewImagePath {
    final first = cover.images.value.firstOrNull;
    return first is NewImageItem ? first.file.path : null;
  }

  bool get isAnalyzingCover =>
      cover.nameSuggestion.value == ColorNameSuggestion.pending;
}

List<ColorIssue> _issuesAmong(
  final ProductColorEntryController entry,
  final List<ProductColorEntryController> entries,
) => colorIssuesAt([
  for (final other in entries) other.toColorItem(),
], entries.indexOf(entry));

typedef AnalyzeColorPhoto =
    Future<Result<ProductImageAnalysis, Failure>> Function(File image);

/// Each colour's photos are analysed once, when it first gets photos, to
/// suggest its name. With [onProductAnalysis] the first successful analysis
/// on the page also pre-fills the product, which is the same garment in every
/// colour. A result for photos removed while it ran is dropped entirely.
ProductColorManager useProductColorManager({
  required final AnalyzeColorPhoto analyze,
  final ValueChanged<Result<ProductImageAnalysis, Failure>>? onProductAnalysis,
  final List<ProductColor>? initialColors,
}) {
  final context = useContext();
  final analyzeRef = useRef(analyze)..value = analyze;
  final onProductAnalysisRef = useRef(onProductAnalysis)
    ..value = onProductAnalysis;
  final isProductFilled = useRef(false);

  Future<void> analyseNewPhotos(final ProductColorEntryController entry) async {
    final photoSet = entry.photoSet;
    if (photoSet == null || photoSet == entry.analysedPhotoSet) return;
    entry.analysedPhotoSet = photoSet;

    bool fillsProduct() =>
        onProductAnalysisRef.value != null && !isProductFilled.value;
    final mainImage = entry.images.value.first;
    if (mainImage is! NewImageItem ||
        !(fillsProduct() || entry.acceptsSuggestedName)) {
      return;
    }

    entry.nameSuggestion.value = ColorNameSuggestion.pending;
    final result = await analyzeRef.value(mainImage.file);
    if (!context.mounted || entry.isDisposed || entry.photoSet != photoSet) {
      return;
    }

    if (fillsProduct()) {
      isProductFilled.value = result.isSuccess;
      onProductAnalysisRef.value?.call(result);
    }
    final color = result.get()?.attributes.color;
    if (color != null) entry.suggestName(color);
    entry.nameSuggestion.value = color == null && entry.acceptsSuggestedName
        ? ColorNameSuggestion.unavailable
        : ColorNameSuggestion.none;
  }

  ProductColorEntryController track(final ProductColorEntryController entry) {
    entry.images.addListener(() => unawaited(analyseNewPhotos(entry)));
    return entry;
  }

  final seed = useMemoized(
    () => initialColors == null || initialColors.isEmpty
        ? [track(ProductColorEntryController())]
        : [
            for (final color in initialColors)
              track(ProductColorEntryController.fromProductColor(color)),
          ],
  );
  final entries = useState(seed);
  final expanded = useState<ProductColorEntryController?>(null);
  final revealRequest = useState<ColorRevealRequest?>(null);
  final showsIssues = useState(false);

  useEffect(() {
    return () {
      for (final entry in entries.value) {
        entry.dispose();
      }
    };
  }, const []);

  // A lone colour's name turns required once a second colour joins, so an
  // unfinished open colour stays open instead of hiding what it still needs.
  ProductColorEntryController? addColor({
    final List<ImageItem> images = const [],
  }) {
    if (entries.value.length >= AppConstants.maxProductColors) return null;
    final open = entries.value.length == 1
        ? entries.value.single
        : expanded.value;
    final entry = track(ProductColorEntryController());
    entries.value = [...entries.value, entry];
    revealRequest.value = ColorRevealRequest(entry);
    expanded.value =
        open != null && _issuesAmong(open, entries.value).isNotEmpty
        ? open
        : entry;
    entry.images.value = images;
    return entry;
  }

  // The removed block keeps its listeners until the rebuild unmounts it.
  void removeColor(final ProductColorEntryController entry) {
    entries.value = [...entries.value]..remove(entry);
    if (expanded.value == entry) expanded.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => entry.dispose());
  }

  void reorder(final int oldIndex, final int newIndex) {
    final updated = [...entries.value];
    final entry = updated.removeAt(oldIndex);
    updated.insert(newIndex.clamp(0, updated.length), entry);
    entries.value = updated;
  }

  return ProductColorManager(
    entries: entries.value,
    addColor: addColor,
    removeColor: removeColor,
    reorder: reorder,
    expanded: expanded.value,
    revealRequest: revealRequest.value,
    expand: (final entry) {
      expanded.value = entry;
      revealRequest.value = ColorRevealRequest(entry);
    },
    collapse: () => expanded.value = null,
    showsIssues: showsIssues.value,
    showIssues: () => showsIssues.value = true,
  );
}
