import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_result.freezed.dart';

@freezed
sealed class TryonResult with _$TryonResult {
  const factory TryonResult({
    required final String id,
    required final TryonMode mode,
    final String? imageUrl,
    final String? videoUrl,
    final DailyUsage? usage,
  }) = _TryonResult;

  const TryonResult._();

  String? get mediaUrl => switch (mode) {
    TryonMode.video => videoUrl,
    TryonMode.image => imageUrl,
  };
}
