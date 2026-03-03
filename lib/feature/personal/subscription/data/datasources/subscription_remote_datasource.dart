import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _subscriptionTable = AppConstants.tableSubscriptions;

  Future<SubscriptionModel> getSubscription(final String userId) async {
    final response = await _supabaseClient
        .from(_subscriptionTable)
        .select('user_id, plan')
        .eq('user_id', userId)
        .single();

    return SubscriptionModel.fromJson(response);
  }

  Future<SubscriptionModel> updateSubscription({
    required final SubscriptionPlan targetPlan,
  }) async {
    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionUpdateSubscription,
      body: {'targetPlan': targetPlan.name},
    );
    return SubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
