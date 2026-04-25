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

/// UI display label extension for [ProductThickness] in Presentation Layer.
extension ProductThicknessX on ProductThickness {
  String get label => switch (this) {
    ProductThickness.low => '薄',
    ProductThickness.medium => '中',
    ProductThickness.high => '厚',
  };
}

/// UI display label extension for [ProductSeason] in Presentation Layer.
extension ProductSeasonX on ProductSeason {
  String get label => switch (this) {
    ProductSeason.spring => '春',
    ProductSeason.summer => '夏',
    ProductSeason.autumn => '秋',
    ProductSeason.winter => '冬',
  };
}
