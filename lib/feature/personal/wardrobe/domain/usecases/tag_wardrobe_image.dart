import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/label_result.dart';
import '../services/label_tagger.dart';

class TagWardrobeImage {
  TagWardrobeImage(this._labelTagger);

  final LabelTagger _labelTagger;

  Future<Result<LabelResult, Failure>> call(final File image) =>
      _labelTagger.analyze(image);
}
