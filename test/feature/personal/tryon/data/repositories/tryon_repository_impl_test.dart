import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_response_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemoteDataSource implements TryonRemoteDataSource {
  _FakeRemoteDataSource(this.response);

  final TryonResponseDto response;

  @override
  Future<TryonResponseDto> tryon(final TryonFunctionRequest request) async =>
      response;
}

void main() {
  const request = TryonRequest(
    requestId: 'r1',
    garments: [TryonGarment.product(productId: 'p1')],
    mode: TryonMode.video,
    engine: TryonEngine.standard,
  );

  Future<TryonResult?> run(final TryonResponseDto response) async =>
      (await TryonRepositoryImpl(
        remoteDataSource: _FakeRemoteDataSource(response),
      ).tryon(request)).get();

  test('combines the response with the id and mode of the request', () async {
    final result = await run(
      const TryonResponseDto(videoUrl: 'https://cdn/v.mp4'),
    );

    expect(
      result,
      const TryonResult(
        id: 'r1',
        mode: TryonMode.video,
        videoUrl: 'https://cdn/v.mp4',
      ),
    );
  });
}
