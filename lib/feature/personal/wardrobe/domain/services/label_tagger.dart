import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/label_result.dart';

abstract interface class LabelTagger {
  Future<Result<LabelResult, Failure>> analyze(final File image);
}
