enum ProductElasticity {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  const ProductElasticity(this.value);
  final String value;
}

enum ProductFit {
  slim('slim'),
  regular('regular'),
  oversize('oversize');

  const ProductFit(this.value);
  final String value;
}
