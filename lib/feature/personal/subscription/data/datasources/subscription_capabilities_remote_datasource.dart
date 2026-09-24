import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/dtos/subscription_tier_dto.dart';

class SubscriptionCapabilitiesRemoteDataSource {
  SubscriptionCapabilitiesRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<SubscriptionTierDto> getTierCapabilities(final AppSubscriptionTier tier) async {
    final response = await _supabaseClient
        .from(AppConstants.tableSubscriptionTiers)
        .select()
        .eq('id', tier.value)
        .single();

    return SubscriptionTierDto.fromJson(response);
  }
}
