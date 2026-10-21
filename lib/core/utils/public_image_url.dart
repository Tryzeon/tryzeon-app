import 'package:tryzeon/core/config/env.dart';

/// Public URL of an object in the R2 public images bucket, built from its key.
abstract final class PublicImageUrl {
  static String of(final String key) => '${Env().r2PublicImagesBaseUrl}/$key';

  static String? ofOrNull(final String? key) =>
      key == null || key.isEmpty ? null : of(key);
}
