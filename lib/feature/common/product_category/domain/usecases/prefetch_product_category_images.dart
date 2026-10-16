import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/image_prefetch/domain/services/image_prefetcher.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class PrefetchProductCategoryImages {
  PrefetchProductCategoryImages({
    required final ProductCategoryRepository repository,
    required final ImagePrefetcher imagePrefetcher,
  }) : _repository = repository,
       _imagePrefetcher = imagePrefetcher;

  final ProductCategoryRepository _repository;
  final ImagePrefetcher _imagePrefetcher;

  Future<Result<void, Failure>> call() async {
    final categories = await _repository.getProductCategories();
    if (categories case Err(:final error)) return Err(error);

    return _imagePrefetcher.prefetch(
      categories
          .get()!
          .expand(
            (final category) => [
              category.imageMaleUrl,
              category.imageFemaleUrl,
            ],
          )
          .nonNulls,
    );
  }
}
