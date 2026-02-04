import 'package:equatable/equatable.dart';

class StoreAnalyticsSummary extends Equatable {
  const StoreAnalyticsSummary({
    required this.totalTryonCount,
    required this.totalPurchaseClickCount,
  });

  final int totalTryonCount;
  final int totalPurchaseClickCount;

  @override
  List<Object?> get props => [totalTryonCount, totalPurchaseClickCount];
}
