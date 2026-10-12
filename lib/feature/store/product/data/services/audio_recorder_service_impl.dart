import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/services/audio_recorder_service.dart';
import 'package:typed_result/typed_result.dart';

class AudioRecorderServiceImpl implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  String get mimeType => 'audio/mp4';

  @override
  Future<Result<RecorderStartResult, Failure>> start() async {
    try {
      if (!await _recorder.hasPermission()) {
        return const Ok(RecorderStartResult.permissionDenied);
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/size_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _path = path;
      return const Ok(RecorderStartResult.started);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start recording', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Recording, Failure>> stop() async {
    try {
      final path = await _recorder.stop();
      final target = path ?? _path;
      _path = null;
      if (target == null) return Ok((bytes: null, mimeType: mimeType));
      final file = File(target);
      if (!await file.exists()) return Ok((bytes: null, mimeType: mimeType));
      final bytes = await file.readAsBytes();
      try {
        await file.delete();
      } catch (e, st) {
        AppLogger.warning('Failed to delete temp recording file', e, st);
      }
      return Ok((bytes: bytes, mimeType: mimeType));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stop recording', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> cancel() async {
    try {
      await _recorder.cancel();
      _path = null;
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to cancel recording', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
