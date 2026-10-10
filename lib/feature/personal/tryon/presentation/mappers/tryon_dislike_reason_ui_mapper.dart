import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';

extension TryonDislikeReasonUiMapper on TryonDislikeReason {
  String get label => switch (this) {
    TryonDislikeReason.identityMismatch => '臉不像我',
    TryonDislikeReason.garmentUnfaithful => '服飾不像原圖',
    TryonDislikeReason.garmentDeformed => '服飾變形',
    TryonDislikeReason.bodyShape => '身材不對',
    TryonDislikeReason.handsPose => '手部或姿勢怪怪的',
  };
}
