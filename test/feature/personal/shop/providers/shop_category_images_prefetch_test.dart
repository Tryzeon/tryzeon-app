import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_category/domain/usecases/prefetch_product_category_images.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakePrefetchProductCategoryImages
    implements PrefetchProductCategoryImages {
  Result<void, Failure> result = const Ok(null);
  int calls = 0;

  @override
  Future<Result<void, Failure>> call() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakePrefetchProductCategoryImages prefetch;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        prefetchProductCategoryImagesUseCaseProvider.overrideWithValue(
          prefetch,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    prefetch = _FakePrefetchProductCategoryImages();
  });

  test('prefetches the category images', () async {
    final container = makeContainer();

    await container.read(shopCategoryImagesPrefetchProvider.future);

    expect(prefetch.calls, 1);
  });

  test('a failed prefetch is only logged, never surfaced', () async {
    AppLogger.talker.cleanHistory();
    prefetch.result = const Err(NetworkFailure());
    final container = makeContainer();

    await expectLater(
      container.read(shopCategoryImagesPrefetchProvider.future),
      completes,
    );
    expect(
      AppLogger.talker.history.where(
        (final log) =>
            log.logLevel == LogLevel.warning &&
            (log.message ?? '').contains('category images'),
      ),
      hasLength(1),
    );
  });
}
