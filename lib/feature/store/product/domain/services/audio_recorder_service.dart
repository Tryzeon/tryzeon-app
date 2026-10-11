import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

enum RecorderStartResult { started, permissionDenied }

typedef Recording = ({Uint8List? bytes, String mimeType});

abstract interface class AudioRecorderService {
  Future<Result<RecorderStartResult, Failure>> start();
  Future<Result<Recording, Failure>> stop();
  Future<Result<void, Failure>> cancel();
  String get mimeType;
}
