import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

Map<String, dynamic> _body(final TryonRequest request) => switch (request) {
  TryonGenerateRequest() =>
    const PersonalMappr().convert<TryonGenerateRequest, TryonFunctionRequest>(
      request,
    ),
  TryonAnimateRequest() =>
    const PersonalMappr().convert<TryonAnimateRequest, TryonFunctionRequest>(
      request,
    ),
}.toJson();

void main() {
  const garments = [TryonGarment.product(productId: 'p1')];

  test('omits the avatar field entirely when there is no override', () {
    final body = _body(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body.containsKey('avatar'), isFalse);
    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends a custom avatar as inline base64', () {
    final body = _body(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
        avatarBase64: 'AAAA',
      ),
    );

    expect(body['avatar'], {'base64': 'AAAA'});
  });

  test('sends a product garment with its size when one is known', () {
    final body = _body(
      const TryonRequest.generate(
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

  test('wraps each of a garment\'s own photos as inline bytes', () {
    final body = _body(
      const TryonRequest.generate(
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
      const TryonRequest.generate(
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
      const TryonRequest.generate(
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

  test('sends an animate request as a baseImage with no garments', () {
    final body = _body(
      const TryonRequest.animate(
        requestId: 'r1',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.standard,
        transitionPrompt: 'spin',
      ),
    );

    expect(body['mode'], 'video');
    expect(body['baseImage'], {'base64': 'FINISHED'});
    expect(body['transitionPrompt'], 'spin');
    expect(body.containsKey('garments'), isFalse);
    expect(body.containsKey('avatar'), isFalse);
    expect(body.containsKey('scenePrompt'), isFalse);
    expect(body.containsKey('stylingPrompt'), isFalse);
  });

  test('omits the transitionPrompt when the user set no style', () {
    final body = _body(
      const TryonRequest.animate(
        requestId: 'r1',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.standard,
      ),
    );

    expect(body.containsKey('transitionPrompt'), isFalse);
  });

  test('a generate request never carries a baseImage', () {
    final body = _body(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.video,
        engine: TryonEngine.standard,
      ),
    );

    expect(body.containsKey('baseImage'), isFalse);
    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends the stylingPrompt when the user set one', () {
    final body = _body(
      const TryonRequest.generate(
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
      const TryonRequest.generate(
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
      const TryonRequest.generate(
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
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['engine'], 'standard');
  });

  test(
    'an animate request carries the engine even though no image is generated',
    () {
      final body = _body(
        const TryonRequest.animate(
          requestId: 'r1',
          baseImageBase64: 'FINISHED',
          engine: TryonEngine.experimental,
        ),
      );

      expect(body['engine'], 'experimental');
    },
  );

  test('an animate request reports video as its mode', () {
    const request = TryonRequest.animate(
      requestId: 'r1',
      baseImageBase64: 'FINISHED',
      engine: TryonEngine.standard,
    );

    expect(request.mode, TryonMode.video);
  });

  test('names the generation with the request id', () {
    final body = _body(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    );

    expect(body['generationId'], 'r1');
  });

  test('names an animate generation with the request id', () {
    final body = _body(
      const TryonRequest.animate(
        requestId: 'r2',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.standard,
      ),
    );

    expect(body['generationId'], 'r2');
  });
}
