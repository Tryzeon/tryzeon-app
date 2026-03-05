import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_model.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<SubscriptionModel> getSubscription(final String userId) async {
    final response = await _supabaseClient
        .from(AppConstants.tableSubscriptions)
        .select('user_id, plan')
        .eq('user_id', userId)
        .single();

    return SubscriptionModel.fromJson(response);
  }

  Future<SubscriptionModel> updateSubscription({required final String targetPlan}) async {
    final response = await _supabaseClient.functions.invoke(
      AppConstants.functionUpdateSubscription,
      body: {'targetPlan': targetPlan},
    );
    return SubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SubscriptionPlanModel>> getSubscriptionPlans() async {
    final response = await _supabaseClient
        .from(AppConstants.tableSubscriptionPlans)
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return response.map(SubscriptionPlanModel.fromJson).toList();
  }
}
