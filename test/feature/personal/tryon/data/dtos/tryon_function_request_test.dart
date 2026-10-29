import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/mappers/tryon_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

Map<String, dynamic> _body(final TryonRequest request) => const TryonMappr()
    .convert<TryonRequest, TryonFunctionRequest>(request)
    .toJson();

void main() {
  const garments = [TryonGarment.product(productId: 'p1')];

  test('sends a product garment with its size when one is known', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: [TryonGarment.product(productId: 'p1', sizeId: 's1')],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['garments'], [
      {'productId': 'p1', 'sizeId': 's1'},
    ]);
  });

  test('sends a product garment\'s colour only when one is chosen', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: [
          TryonGarment.product(productId: 'p1', colorId: 'c1'),
          TryonGarment.product(productId: 'p2'),
        ],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['garments'], [
      {'productId': 'p1', 'colorId': 'c1'},
      {'productId': 'p2'},
    ]);
  });

  test('wraps each of a garment\'s own photos as inline bytes', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: [
          TryonGarment.images(base64Images: ['AAAA', 'BBBB']),
        ],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['garments'], [
      {
        'images': [
          {'base64': 'AAAA'},
          {'base64': 'BBBB'},
        ],
      },
    ]);
  });

  test('sends a wardrobe garment as a bare item reference', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: [TryonGarment.wardrobe(wardrobeItemId: 'w1')],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['garments'], [
      {'wardrobeItemId': 'w1'},
    ]);
  });

  test('omits the sizeId key entirely when no size is known', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends the transitionPrompt when the user set one', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.video,
        engine: TryonEngine.standard,
        transitionPrompt: 'spin',
      ),
    );

    expect(body['transitionPrompt'], 'spin');
  });

  test('omits the transitionPrompt when the user set no style', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.video,
        engine: TryonEngine.standard,
      ),
    );

    expect(body.containsKey('transitionPrompt'), isFalse);
  });

  test('sends the stylingPrompt when the user set one', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
        stylingPrompt: 'tucked in',
      ),
    );

    expect(body['stylingPrompt'], 'tucked in');
  });

  test('omits the stylingPrompt when the user set no styling', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body.containsKey('stylingPrompt'), isFalse);
  });

  test('sends the engine only when the user picked the experimental one', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.experimental,
      ),
    );

    expect(body['engine'], 'experimental');
  });

  test('names the engine on every body, the standard one included', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['engine'], 'standard');
  });

  test('names the generation with the request id', () {
    final body = _body(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['generationId'], 'r1');
  });
}
