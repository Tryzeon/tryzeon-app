import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_tier_model.dart';

class SubscriptionCapabilitiesRemoteDataSource {
  SubscriptionCapabilitiesRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<SubscriptionTierModel> getTierCapabilities(
    final AppSubscriptionTier tier,
  ) async {
    final response = await _supabaseClient
        .from(AppConstants.tableSubscriptionTiers)
        .select()
        .eq('id', tier.value)
        .single();

    return SubscriptionTierModel.fromJson(response);
  }
}
