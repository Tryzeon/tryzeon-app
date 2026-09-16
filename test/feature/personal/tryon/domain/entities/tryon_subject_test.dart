import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';

void main() {
  const product = TryonSubject.generate(
    pieces: [
      OutfitPiece.product(
        productId: 'p1',
        name: 'Tee',
        imageUrl: 'u',
        garmentType: GarmentType.top,
        sizeId: 's1',
      ),
    ],
    mode: TryonMode.image,
  );

  test('a generate subject reports the mode it was asked for', () {
    expect(product.mode, TryonMode.image);
    expect(
      const TryonSubject.generate(pieces: [], mode: TryonMode.video).mode,
      TryonMode.video,
    );
  });

  test('an animated subject is always a video', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: product);

    expect(subject.mode, TryonMode.video);
  });

  test('an animated subject shows the pieces its base image was made from', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: product);

    expect(subject.pieces, product.pieces);
  });
}
