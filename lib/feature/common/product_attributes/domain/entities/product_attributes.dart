import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ProductGender {
  male('male'),
  female('female'),
  unisex('unisex');

  const ProductGender(this.value);
  final String value;

  static ProductGender? tryFromString(final String? value) =>
      ProductGender.values.where((final e) => e.value == value).firstOrNull;
}

@JsonEnum(valueField: 'value')
enum ProductStatus {
  active('active'),
  archived('archived');

  const ProductStatus(this.value);
  final String value;

  static ProductStatus? tryFromString(final String? value) =>
      ProductStatus.values.where((final e) => e.value == value).firstOrNull;
}

@JsonEnum(valueField: 'value')
enum ProductFit {
  slim('slim'),
  regular('regular'),
  loose('loose'),
  oversize('oversize');

  const ProductFit(this.value);
  final String value;

  static ProductFit? tryFromString(final String? value) =>
      ProductFit.values.where((final e) => e.value == value).firstOrNull;
}

@JsonEnum(valueField: 'value')
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

@JsonEnum(valueField: 'value')
enum ProductThickness {
  low('low'),
  medium('medium'),
  high('high');

  const ProductThickness(this.value);
  final String value;

  static ProductThickness? tryFromString(final String? value) =>
      ProductThickness.values.where((final e) => e.value == value).firstOrNull;
}

@JsonEnum(valueField: 'value')
enum ProductSeason {
  spring('spring'),
  summer('summer'),
  autumn('autumn'),
  winter('winter');

  const ProductSeason(this.value);
  final String value;

  static ProductSeason? tryFromString(final String? value) =>
      ProductSeason.values.where((final e) => e.value == value).firstOrNull;

  static List<ProductSeason>? listFromStrings(final Iterable<String>? values) =>
      values?.map(tryFromString).whereType<ProductSeason>().toList();

  static List<ProductSeason> listFromSet(final Set<ProductSeason> seasons) =>
      ProductSeason.values.where(seasons.contains).toList();
}
