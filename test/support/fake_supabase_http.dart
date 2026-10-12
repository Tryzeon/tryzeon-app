import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [SupabaseClient] whose every HTTP call answers with [status] and [body].
SupabaseClient supabaseAnswering(final int status, final Object body) {
  final client = MockClient(
    (final request) async => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    ),
  );
  return SupabaseClient('http://127.0.0.1:1', 'anon', httpClient: client);
}

Future<void> signIn(final SupabaseClient client) =>
    client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'refresh_token': 'refresh',
        'user': {
          'id': 'u1',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
