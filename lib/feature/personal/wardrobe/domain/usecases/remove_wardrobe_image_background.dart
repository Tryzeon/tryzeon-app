import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

import '../services/background_remover.dart';

class RemoveWardrobeImageBackground {
  RemoveWardrobeImageBackground(this._backgroundRemover);

  final BackgroundRemover _backgroundRemover;

  Future<Result<Uint8List?, Failure>> call(final File image) =>
      _backgroundRemover.remove(image);
}
