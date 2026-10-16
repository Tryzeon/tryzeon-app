import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// Downloads public images into the disk cache that `CachedNetworkImage`
/// reads, keyed by URL, so a later render of the same URL is a cache hit.
abstract class ImagePrefetcher {
  Future<Result<void, Failure>> prefetch(final Iterable<String> urls);
}
