import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';

extension OutfitPieceLabel on OutfitPiece {
  /// 上衣 / 褲子 / … ; a picked photo has no type.
  String get typeLabel => switch (this) {
    OutfitPieceWardrobe(:final garmentType) ||
    OutfitPieceProduct(:final garmentType) => garmentType.displayName,
    OutfitPieceLocal() => '照片',
  };

  /// Only shop products have a name of their own.
  String? get name => switch (this) {
    OutfitPieceProduct(:final name) => name,
    _ => null,
  };

  String get label => name ?? typeLabel;
}
