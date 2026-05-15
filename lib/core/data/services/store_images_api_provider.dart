import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';

part 'store_images_api_provider.g.dart';

@riverpod
StoreImagesApi storeImagesApi(final Ref ref) {
  return StoreImagesApi(Supabase.instance.client);
}
