import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/models/analytics_event_model.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Upload a batch of analytics events to the backend
  Future<void> uploadAnalyticsEvents(final List<AnalyticsEventModel> events) async {
    if (events.isEmpty) {
      return;
    }

    final eventsJson = events.map((final e) => e.toJson()).toList();

    await _supabaseClient.rpc(
      AppConstants.functionLogAnalyticsEvents,
      params: {'p_events': eventsJson},
    );
  }
}
