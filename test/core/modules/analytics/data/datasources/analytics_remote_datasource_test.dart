import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';

class _SignedOutAuth implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeSupabase implements SupabaseClient {
  @override
  final GoTrueClient auth = _SignedOutAuth();

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('uploading while signed out fails instead of dropping events', () async {
    final dataSource = AnalyticsRemoteDataSource(_FakeSupabase());

    await expectLater(
      dataSource.uploadAnalyticsEvents(const [
        AnalyticsEventDto(productId: 'p1', storeId: 's1', eventType: 'view'),
      ]),
      throwsA(isA<UnauthenticatedException>()),
    );
  });
}
