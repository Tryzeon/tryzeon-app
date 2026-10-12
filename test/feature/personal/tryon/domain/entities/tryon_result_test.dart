import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';

void main() {
  test('the media of a result follows its mode', () {
    const image = TryonResult(
      id: 't1',
      mode: TryonMode.image,
      imageUrl: 'https://cdn/t1.jpg',
      videoUrl: 'https://cdn/t1.mp4',
    );

    expect(image.mediaUrl, 'https://cdn/t1.jpg');
    expect(
      image.copyWith(mode: TryonMode.video).mediaUrl,
      'https://cdn/t1.mp4',
    );
  });
}
