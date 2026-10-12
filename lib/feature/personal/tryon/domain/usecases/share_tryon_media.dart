import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

class ShareTryonMedia {
  ShareTryonMedia({required final TryonMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryonMediaRepository _mediaRepository;

  Future<Result<void, Failure>> call(final TryonResult result) async {
    final url = result.mediaUrl;
    if (url == null || url.isEmpty) {
      return Err(ValidationFailure('${result.mode.name} URL is missing'));
    }
    return _mediaRepository.share(url: url, mode: result.mode);
  }
}
