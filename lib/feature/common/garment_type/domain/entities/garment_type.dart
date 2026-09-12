enum GarmentType {
  top('top'),
  pants('pants'),
  skirt('skirt'),
  dress('dress'),
  outerwear('outerwear'),
  others('others');

  const GarmentType(this.value);
  final String value;

  static GarmentType? tryFromString(final String? value) =>
      GarmentType.values.where((final e) => e.value == value).firstOrNull;
}
