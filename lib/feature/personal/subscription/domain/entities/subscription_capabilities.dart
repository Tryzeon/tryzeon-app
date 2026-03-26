import 'package:equatable/equatable.dart';

class SubscriptionCapabilities extends Equatable {
  const SubscriptionCapabilities({
    required this.requiresWatermark,
    required this.hasVideoAccess,
    required this.wardrobeLimit,
  });

  final bool requiresWatermark;
  final bool hasVideoAccess;
  final int wardrobeLimit;

  @override
  List<Object?> get props => [requiresWatermark, hasVideoAccess, wardrobeLimit];
}
