import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';

const maxColorNameLength = 20;

enum ColorIssue {
  missingImages,
  tooManyImages,
  missingName,
  nameTooLong,
  duplicateName;

  bool get concernsName => switch (this) {
    missingImages || tooManyImages => false,
    missingName || nameTooLong || duplicateName => true,
  };
}

String? normalizeColorName(final String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

ColorIssue? colorNameIssue(
  final String? name, {
  required final List<String?> otherNames,
}) {
  final normalized = normalizeColorName(name);
  if (normalized == null) {
    return otherNames.isEmpty ? null : ColorIssue.missingName;
  }
  if (normalized.length > maxColorNameLength) return ColorIssue.nameTooLong;
  if (otherNames.map(normalizeColorName).contains(normalized)) {
    return ColorIssue.duplicateName;
  }
  return null;
}

List<ColorIssue> colorIssuesAt(final List<ColorItem> colors, final int index) {
  final color = colors[index];
  final otherNames = [
    for (final (i, other) in colors.indexed)
      if (i != index) other.name,
  ];
  return [
    if (color.images.isEmpty) ColorIssue.missingImages,
    if (color.images.length > AppConstants.maxProductImages)
      ColorIssue.tooManyImages,
    ?colorNameIssue(color.name, otherNames: otherNames),
  ];
}

bool isValidColorSet(final List<ColorItem> colors) =>
    colors.isNotEmpty &&
    colors.length <= AppConstants.maxProductColors &&
    Iterable<int>.generate(
      colors.length,
    ).every((final index) => colorIssuesAt(colors, index).isEmpty);
