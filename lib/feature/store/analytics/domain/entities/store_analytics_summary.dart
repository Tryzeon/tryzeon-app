import 'package:equatable/equatable.dart';

class StoreAnalyticsSummary extends Equatable {
  const StoreAnalyticsSummary({
    required this.totalViewCount,
    required this.totalTryonCount,
    required this.totalPurchaseClickCount,
  });

  final int totalViewCount;
  final int totalTryonCount;
  final int totalPurchaseClickCount;

  @override
  List<Object?> get props => [totalViewCount, totalTryonCount, totalPurchaseClickCount];
}
