import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';

class SubscriptionCapabilitiesRemoteDataSource {
  SubscriptionCapabilitiesRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<SubscriptionPlanModel> getPlanCapabilities(final String planId) async {
    final response = await _supabaseClient
        .from(AppConstants.tableSubscriptionPlans)
        .select()
        .eq('id', planId)
        .eq('is_active', true)
        .single();

    return SubscriptionPlanModel.fromJson(response);
  }
}
