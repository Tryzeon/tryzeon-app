import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/image_prefetch/domain/services/image_prefetcher.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_category/domain/usecases/prefetch_product_category_images.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements ProductCategoryRepository {
  Result<List<ProductCategory>, Failure> result = const Ok([]);

  @override
  Future<Result<List<ProductCategory>, Failure>> getProductCategories({
    final bool forceRefresh = false,
  }) async => result;
}

class _FakeImagePrefetcher implements ImagePrefetcher {
  final List<List<String>> calls = [];

  @override
  Future<Result<void, Failure>> prefetch(final Iterable<String> urls) async {
    calls.add(urls.toList());
    return const Ok(null);
  }
}

ProductCategory _category(
  final String id, {
  final ProductGender gender = ProductGender.unisex,
  final String? male,
  final String? female,
}) => ProductCategory(
  id: id,
  code: id,
  name: id,
  gender: gender,
  defaultGarmentType: GarmentType.top,
  imageMaleUrl: male,
  imageFemaleUrl: female,
);

void main() {
  late _FakeRepository repository;
  late _FakeImagePrefetcher imagePrefetcher;
  late PrefetchProductCategoryImages prefetchProductCategoryImages;

  setUp(() {
    repository = _FakeRepository();
    imagePrefetcher = _FakeImagePrefetcher();
    prefetchProductCategoryImages = PrefetchProductCategoryImages(
      repository: repository,
      imagePrefetcher: imagePrefetcher,
    );
  });

  test('prefetches every category image for both genders', () async {
    repository.result = Ok([
      _category('tee', male: 'tee-m', female: 'tee-f'),
      _category('dress', gender: ProductGender.female, female: 'dress-f'),
      _category('tie', gender: ProductGender.male, male: 'tie-m'),
      _category('socks'),
    ]);

    final result = await prefetchProductCategoryImages();

    expect(result.isSuccess, isTrue);
    expect(imagePrefetcher.calls, [
      ['tee-m', 'tee-f', 'dress-f', 'tie-m'],
    ]);
  });

  test('categories that cannot load prefetch nothing', () async {
    repository.result = const Err(NetworkFailure());

    final result = await prefetchProductCategoryImages();

    expect(result.getError(), const NetworkFailure());
    expect(imagePrefetcher.calls, isEmpty);
  });
}
