import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/subscription/data/models/subscription_model.dart';

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _subscriptionTable = AppConstants.tableSubscription;

  Future<SubscriptionModel> getSubscription(final String userId) async {
    final response = await _supabaseClient
        .from(_subscriptionTable)
        .select('user_id, plan')
        .eq('user_id', userId)
        .single();

    return SubscriptionModel.fromJson(response);
  }
}
