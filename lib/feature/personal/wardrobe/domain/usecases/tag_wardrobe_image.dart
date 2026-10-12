import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/label_tagger.dart';
import 'package:typed_result/typed_result.dart';

class TagWardrobeImage {
  TagWardrobeImage(this._labelTagger);

  final LabelTagger _labelTagger;

  Future<Result<LabelResult, Failure>> call(final File image) =>
      _labelTagger.analyze(image);
}
