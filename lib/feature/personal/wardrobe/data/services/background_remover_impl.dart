import 'dart:io';
import 'dart:typed_data';

import 'package:image_background_remover/image_background_remover.dart' as bg;
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/background_remover.dart';
import 'package:typed_result/typed_result.dart';

class BackgroundRemoverImpl implements BackgroundRemover {
  BackgroundRemoverImpl();

  Future<void>? _initFuture;

  Future<void> _ensureInit() async {
    final existing = _initFuture;
    if (existing != null) return existing;
    final future = bg.BackgroundRemover.instance.initializeOrt();
    _initFuture = future;
    try {
      await future;
    } catch (e, st) {
      AppLogger.warning(
        'Background remover init failed; will retry next call',
        e,
        st,
      );
      _initFuture = null;
      rethrow;
    }
  }

  @override
  Future<Result<Uint8List?, Failure>> remove(final File image) async {
    try {
      final bytes = await image.readAsBytes();
      await _ensureInit();
      return Ok(await bg.BackgroundRemover.instance.removeBgBytes(bytes));
    } catch (e, stackTrace) {
      AppLogger.warning('Background removal failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
