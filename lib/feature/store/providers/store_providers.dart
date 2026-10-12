import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/store/data/services/store_images_api.dart';

part 'store_providers.g.dart';

@riverpod
StoreImagesApi storeImagesApi(final Ref ref) {
  return StoreImagesApi(
    ref.watch(supabaseClientProvider),
    ref.watch(dioProvider),
  );
}
