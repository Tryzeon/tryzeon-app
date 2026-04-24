import '../../domain/value_objects/product_attributes.dart';

/// UI display label extension for [ProductElasticity] in Presentation Layer.
extension ProductElasticityX on ProductElasticity {
  String get label => switch (this) {
    ProductElasticity.none => '無',
    ProductElasticity.low => '低',
    ProductElasticity.medium => '中',
    ProductElasticity.high => '高',
  };
}

/// UI display label extension for [ProductFit] in Presentation Layer.
extension ProductFitX on ProductFit {
  String get label => switch (this) {
    ProductFit.slim => '合身',
    ProductFit.regular => '常規',
    ProductFit.plusSize => '大尺碼',
    ProductFit.oversize => 'Oversize',
  };
}

/// UI display label extension for [ProductThickness] in Presentation Layer.
extension ProductThicknessX on ProductThickness {
  String get label => switch (this) {
    ProductThickness.low => '薄',
    ProductThickness.medium => '中',
    ProductThickness.high => '厚',
  };
}
