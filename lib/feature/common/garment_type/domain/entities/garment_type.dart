enum GarmentType {
  top('top'),
  pants('pants'),
  skirt('skirt'),
  onePiece('one_piece'),
  outerwear('outerwear'),
  others('others');

  const GarmentType(this.value);
  final String value;

  static GarmentType? tryFromString(final String? value) =>
      GarmentType.values.where((final e) => e.value == value).firstOrNull;
}
