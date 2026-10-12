import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/log_analytics_events_request.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _logAnalyticsEventsRpc = 'log_analytics_events';

  Future<void> uploadAnalyticsEvents(
    final List<AnalyticsEventDto> events,
  ) async {
    if (events.isEmpty) return;
    if (_supabaseClient.auth.currentUser == null) {
      throw const UnauthenticatedException();
    }

    await _supabaseClient.rpc<void>(
      _logAnalyticsEventsRpc,
      params: LogAnalyticsEventsRequest(events: events).toJson(),
    );
  }
}
