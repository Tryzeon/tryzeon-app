import '../../domain/value_objects/product_attributes.dart';

extension ProductElasticityX on ProductElasticity {
  String get label {
    switch (this) {
      case ProductElasticity.none:
        return '無';
      case ProductElasticity.low:
        return '低';
      case ProductElasticity.medium:
        return '中';
      case ProductElasticity.high:
        return '高';
    }
  }
}

extension ProductFitX on ProductFit {
  String get label {
    switch (this) {
      case ProductFit.slim:
        return '合身';
      case ProductFit.regular:
        return '常規';
      case ProductFit.oversize:
        return 'Oversize';
    }
  }
}
