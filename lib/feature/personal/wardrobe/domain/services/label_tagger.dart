import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class LabelTagger {
  Future<Result<LabelResult, Failure>> analyze(final File image);
}
