import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';

class SubscriptionModel extends Subscription {
  const SubscriptionModel({required super.userId, required super.plan});

  factory SubscriptionModel.fromJson(final Map<String, dynamic> json) {
    return SubscriptionModel(
      userId: json['user_id'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (final e) => e.name == (json['plan'] as String).toLowerCase(),
        orElse: () => SubscriptionPlan.free,
      ),
    );
  }
}
