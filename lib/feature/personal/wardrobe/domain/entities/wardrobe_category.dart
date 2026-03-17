enum WardrobeCategory {
  top('top'),
  pants('pants'),
  skirt('skirt'),
  jacket('jacket'),
  shoes('shoes'),
  accessories('accessories'),
  others('others');

  const WardrobeCategory(this.value);
  final String value;

  static WardrobeCategory? tryFromString(final String? value) =>
      WardrobeCategory.values.where((final e) => e.value == value).firstOrNull;
}
