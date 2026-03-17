enum ProductElasticity {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  const ProductElasticity(this.value);
  final String value;

  static ProductElasticity? tryFromString(final String? value) =>
      ProductElasticity.values.where((final e) => e.value == value).firstOrNull;
}

enum ProductFit {
  slim('slim'),
  regular('regular'),
  oversize('oversize');

  const ProductFit(this.value);
  final String value;

  static ProductFit? tryFromString(final String? value) =>
      ProductFit.values.where((final e) => e.value == value).firstOrNull;
}
